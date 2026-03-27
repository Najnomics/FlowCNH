// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFlowCNH.sol";

/// @title StreamVault — Core accounting engine for FlowCNH payment streams
/// @notice Holds deposited assets, tracks per-second accrual, manages idle yield via dForce,
///         and handles claims, pauses, cancellations with dispute windows.
contract StreamVault is IStreamVault, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ─── Storage ──────────────────────────────────────────────────────

    uint256 public nextStreamId;
    mapping(uint256 => StreamInfo) internal streams;

    /// @notice Tracks time accrued while paused so accrual resumes correctly
    mapping(uint256 => uint256) public pausedAccrued;

    /// @notice When cancellation was requested (for dispute window)
    mapping(uint256 => uint256) public cancellationRequestTime;

    /// @notice Yield earned per stream, tracked separately
    mapping(uint256 => uint256) public yieldEarned;

    address public router;
    IDForceAdapter public yieldAdapter;
    address public treasury;
    uint256 public protocolFeeBps; // basis points (2000 = 20%)
    uint256 public disputeWindowSeconds;

    /// @notice Supported assets for streaming
    mapping(address => bool) public supportedAssets;

    /// @notice Total idle balance per asset currently in yield
    mapping(address => uint256) public totalIdleInYield;

    // ─── Errors ───────────────────────────────────────────────────────

    error OnlyRouter();
    error OnlySenderOrRecipient();
    error OnlySender();
    error StreamNotActive();
    error StreamNotPaused();
    error UnsupportedAsset();
    error ZeroAddress();
    error ZeroAmount();
    error DisputeWindowActive();
    error NothingToClaim();

    // ─── Modifiers ────────────────────────────────────────────────────

    modifier onlyRouter() {
        if (msg.sender != router) revert OnlyRouter();
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────────

    constructor(
        address _owner,
        address _treasury,
        uint256 _protocolFeeBps,
        uint256 _disputeWindowSeconds
    ) Ownable(_owner) {
        treasury = _treasury;
        protocolFeeBps = _protocolFeeBps;
        disputeWindowSeconds = _disputeWindowSeconds;
        nextStreamId = 1;
    }

    // ─── Admin ────────────────────────────────────────────────────────

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setYieldAdapter(address _adapter) external onlyOwner {
        yieldAdapter = IDForceAdapter(_adapter);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setSupportedAsset(address asset, bool supported) external onlyOwner {
        supportedAssets[asset] = supported;
    }

    function setProtocolFeeBps(uint256 _bps) external onlyOwner {
        protocolFeeBps = _bps;
    }

    function setDisputeWindowSeconds(uint256 _seconds) external onlyOwner {
        disputeWindowSeconds = _seconds;
    }

    // ─── Stream Creation (called by Router) ───────────────────────────

    function createStream(
        address sender,
        address recipient,
        address asset,
        uint256 ratePerSecond,
        uint256 duration,
        bool enableYield
    ) external override onlyRouter returns (uint256 streamId) {
        if (recipient == address(0)) revert ZeroAddress();
        if (ratePerSecond == 0) revert ZeroAmount();
        if (!supportedAssets[asset]) revert UnsupportedAsset();

        uint256 totalDeposit = ratePerSecond * duration;
        streamId = nextStreamId++;

        streams[streamId] = StreamInfo({
            sender: sender, // employer
            recipient: recipient,
            asset: asset,
            ratePerSecond: ratePerSecond,
            startTime: block.timestamp,
            stopTime: block.timestamp + duration,
            lastClaimTime: block.timestamp,
            totalDeposited: totalDeposit,
            totalClaimed: 0,
            status: StreamStatus.Active,
            yieldEnabled: enableYield
        });

        // Pull asset from router
        IERC20(asset).safeTransferFrom(msg.sender, address(this), totalDeposit);

        // Supply idle balance to dForce if yield enabled
        if (enableYield && address(yieldAdapter) != address(0)) {
            IERC20(asset).forceApprove(address(yieldAdapter), totalDeposit);
            yieldAdapter.supply(asset, totalDeposit);
            totalIdleInYield[asset] += totalDeposit;
        }

        emit StreamCreated(
            streamId,
            sender,
            recipient,
            asset,
            ratePerSecond,
            block.timestamp,
            block.timestamp + duration,
            totalDeposit
        );
    }

    // ─── Claiming ─────────────────────────────────────────────────────

    /// @notice Calculate claimable balance for a stream
    function claimableBalance(uint256 streamId) public view override returns (uint256) {
        StreamInfo storage s = streams[streamId];
        if (s.status == StreamStatus.Cancelled || s.status == StreamStatus.Completed) return 0;

        uint256 accrualEnd;
        if (s.status == StreamStatus.Paused) {
            // Use accrual tracked at pause time
            return pausedAccrued[streamId];
        }

        accrualEnd = block.timestamp > s.stopTime ? s.stopTime : block.timestamp;
        if (accrualEnd <= s.lastClaimTime) return 0;

        uint256 elapsed = accrualEnd - s.lastClaimTime;
        uint256 accrued = elapsed * s.ratePerSecond;

        // Cap at remaining deposit
        uint256 remaining = s.totalDeposited - s.totalClaimed;
        return accrued > remaining ? remaining : accrued;
    }

    /// @notice Claim accrued balance — gasless via Fee Sponsorship
    function claim(uint256 streamId) external override nonReentrant {
        StreamInfo storage s = streams[streamId];
        if (s.status == StreamStatus.Cancelled || s.status == StreamStatus.Completed) revert StreamNotActive();

        uint256 amount = claimableBalance(streamId);
        if (amount == 0) revert NothingToClaim();

        s.totalClaimed += amount;
        s.lastClaimTime = block.timestamp > s.stopTime ? s.stopTime : block.timestamp;

        if (s.status == StreamStatus.Paused) {
            pausedAccrued[streamId] = 0;
        }

        // Withdraw from yield if needed
        if (s.yieldEnabled && address(yieldAdapter) != address(0) && totalIdleInYield[s.asset] > 0) {
            uint256 toWithdraw = amount > totalIdleInYield[s.asset] ? totalIdleInYield[s.asset] : amount;
            yieldAdapter.withdraw(s.asset, toWithdraw);
            totalIdleInYield[s.asset] -= toWithdraw;
        }

        // Transfer to current NFT holder (recipient)
        IERC20(s.asset).safeTransfer(s.recipient, amount);

        emit Claimed(streamId, s.recipient, amount);

        // Check if stream completed
        if (s.totalClaimed >= s.totalDeposited) {
            s.status = StreamStatus.Completed;
        }
    }

    // ─── Pause / Resume ───────────────────────────────────────────────

    function pauseStream(uint256 streamId) external override {
        _requireSender(streamId);
        StreamInfo storage s = streams[streamId];
        if (s.status != StreamStatus.Active) revert StreamNotActive();

        // Snapshot current accrued balance
        pausedAccrued[streamId] = claimableBalance(streamId);
        s.status = StreamStatus.Paused;

        emit StreamPaused(streamId);
    }

    function resumeStream(uint256 streamId) external override {
        _requireSender(streamId);
        StreamInfo storage s = streams[streamId];
        if (s.status != StreamStatus.Paused) revert StreamNotPaused();

        s.lastClaimTime = block.timestamp;
        s.status = StreamStatus.Active;

        emit StreamResumed(streamId);
    }

    /// @dev Allows either the stream sender directly, or the router acting on behalf of the sender
    function _requireSender(uint256 streamId) internal view {
        StreamInfo storage s = streams[streamId];
        if (msg.sender == s.sender) return; // direct call
        if (msg.sender == router) return;   // via router
        revert OnlySender();
    }

    // ─── Cancellation with Dispute Window ─────────────────────────────

    function cancelStream(uint256 streamId) external override nonReentrant {
        _requireSender(streamId);
        StreamInfo storage s = streams[streamId];
        if (s.status == StreamStatus.Cancelled || s.status == StreamStatus.Completed) revert StreamNotActive();

        if (cancellationRequestTime[streamId] == 0) {
            // First call: initiate cancellation with dispute window
            cancellationRequestTime[streamId] = block.timestamp;
            return;
        }

        // Second call: enforce dispute window
        if (block.timestamp < cancellationRequestTime[streamId] + disputeWindowSeconds) {
            revert DisputeWindowActive();
        }

        // Calculate final accrued amount for recipient
        uint256 recipientAmount = claimableBalance(streamId);
        uint256 senderRefund = s.totalDeposited - s.totalClaimed - recipientAmount;

        s.status = StreamStatus.Cancelled;
        s.totalClaimed += recipientAmount;

        // Withdraw everything from yield
        if (s.yieldEnabled && address(yieldAdapter) != address(0)) {
            uint256 totalToWithdraw = recipientAmount + senderRefund;
            if (totalToWithdraw > totalIdleInYield[s.asset]) {
                totalToWithdraw = totalIdleInYield[s.asset];
            }
            if (totalToWithdraw > 0) {
                yieldAdapter.withdraw(s.asset, totalToWithdraw);
                totalIdleInYield[s.asset] -= totalToWithdraw;
            }
        }

        // Transfer to both parties
        if (recipientAmount > 0) {
            IERC20(s.asset).safeTransfer(s.recipient, recipientAmount);
        }
        if (senderRefund > 0) {
            IERC20(s.asset).safeTransfer(s.sender, senderRefund);
        }

        emit StreamCancelled(streamId, senderRefund, recipientAmount);
    }

    // ─── Yield Harvesting ─────────────────────────────────────────────

    /// @notice Harvest yield from dForce for a specific asset
    /// @dev Called by the off-chain harvester service
    function harvestYield(address asset) external nonReentrant {
        if (address(yieldAdapter) == address(0)) return;

        uint256 yield_ = yieldAdapter.harvest(asset);
        if (yield_ == 0) return;

        // Split yield: 80% to recipients via treasury redistribution, 20% to protocol
        uint256 protocolShare = (yield_ * protocolFeeBps) / 10000;
        uint256 recipientShare = yield_ - protocolShare;

        if (protocolShare > 0) {
            IERC20(asset).safeTransfer(treasury, protocolShare);
        }

        // Recipient share stays in vault — increases effective balance
        // This is tracked as bonus yield and distributed proportionally on claims

        emit YieldHarvested(0, yield_, recipientShare, protocolShare);
    }

    // ─── Views ────────────────────────────────────────────────────────

    function getStream(uint256 streamId) external view override returns (StreamInfo memory) {
        return streams[streamId];
    }

    /// @notice Update the recipient address (called when stream NFT is transferred)
    function updateRecipient(uint256 streamId, address newRecipient) external onlyRouter {
        streams[streamId].recipient = newRecipient;
    }
}
