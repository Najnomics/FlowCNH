// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StreamVault.sol";
import "./StreamNFT.sol";

/// @title FlowCNHRouter — Main entry point for creating and managing FlowCNH streams
/// @notice Validates inputs, pulls funds from employer, delegates to StreamVault,
///         mints Stream NFTs, and handles multi-recipient batch creation.
contract FlowCNHRouter is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    StreamVault public vault;
    StreamNFT public streamNFT;

    // ─── Events ───────────────────────────────────────────────────────

    event StreamOpened(
        uint256 indexed streamId,
        uint256 indexed tokenId,
        address indexed sender,
        address recipient,
        address asset,
        uint256 ratePerSecond,
        uint256 duration
    );
    event BatchStreamsOpened(uint256[] streamIds, address indexed sender, uint256 count);

    // ─── Errors ───────────────────────────────────────────────────────

    error ZeroAddress();
    error ZeroRate();
    error ZeroDuration();
    error ArrayLengthMismatch();
    error EmptyBatch();

    // ─── Constructor ──────────────────────────────────────────────────

    constructor(
        address _owner,
        address _vault,
        address _streamNFT
    ) Ownable(_owner) {
        vault = StreamVault(_vault);
        streamNFT = StreamNFT(_streamNFT);
    }

    // ─── Single Stream Creation ───────────────────────────────────────

    /// @notice Create a payment stream to a recipient
    /// @param recipient Worker/recipient wallet address
    /// @param asset ERC-20 token to stream (AxCNH or USDT0)
    /// @param ratePerSecond Payment rate in wei per second
    /// @param duration Stream duration in seconds
    /// @param enableYield Whether to auto-supply idle balance to dForce
    /// @return streamId The created stream ID
    /// @return tokenId The minted NFT token ID
    function createStream(
        address recipient,
        address asset,
        uint256 ratePerSecond,
        uint256 duration,
        bool enableYield
    ) external nonReentrant returns (uint256 streamId, uint256 tokenId) {
        if (recipient == address(0)) revert ZeroAddress();
        if (ratePerSecond == 0) revert ZeroRate();
        if (duration == 0) revert ZeroDuration();

        uint256 totalDeposit = ratePerSecond * duration;

        // Pull funds from employer
        IERC20(asset).safeTransferFrom(msg.sender, address(this), totalDeposit);

        // Approve vault to pull funds
        IERC20(asset).forceApprove(address(vault), totalDeposit);

        // Create stream in vault
        streamId = vault.createStream(msg.sender, recipient, asset, ratePerSecond, duration, enableYield);

        // Mint stream NFT to recipient
        tokenId = streamNFT.mint(recipient, streamId);

        emit StreamOpened(streamId, tokenId, msg.sender, recipient, asset, ratePerSecond, duration);
    }

    // ─── Batch Stream Creation ────────────────────────────────────────

    /// @notice Create multiple streams in a single transaction
    /// @param recipients Array of recipient addresses
    /// @param asset ERC-20 token to stream
    /// @param ratesPerSecond Array of payment rates
    /// @param durations Array of durations
    /// @param enableYield Whether to enable yield for all streams
    function createBatchStreams(
        address[] calldata recipients,
        address asset,
        uint256[] calldata ratesPerSecond,
        uint256[] calldata durations,
        bool enableYield
    ) external nonReentrant returns (uint256[] memory streamIds) {
        uint256 len = recipients.length;
        if (len == 0) revert EmptyBatch();
        if (len != ratesPerSecond.length || len != durations.length) revert ArrayLengthMismatch();

        // Calculate total deposit needed
        uint256 totalDeposit;
        for (uint256 i; i < len; ++i) {
            totalDeposit += ratesPerSecond[i] * durations[i];
        }

        // Pull total funds from employer
        IERC20(asset).safeTransferFrom(msg.sender, address(this), totalDeposit);

        streamIds = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            _createSingleInBatch(
                recipients[i], asset, ratesPerSecond[i], durations[i], enableYield, streamIds, i
            );
        }

        emit BatchStreamsOpened(streamIds, msg.sender, len);
    }

    // ─── Stream Management (delegated to Vault) ───────────────────────

    function pauseStream(uint256 streamId) external {
        vault.pauseStream(streamId);
    }

    function resumeStream(uint256 streamId) external {
        vault.resumeStream(streamId);
    }

    function cancelStream(uint256 streamId) external {
        vault.cancelStream(streamId);
    }

    // ─── Views ────────────────────────────────────────────────────────

    function claimableBalance(uint256 streamId) external view returns (uint256) {
        return vault.claimableBalance(streamId);
    }

    function getStream(uint256 streamId) external view returns (IStreamVault.StreamInfo memory) {
        return vault.getStream(streamId);
    }

    // ─── Internal ─────────────────────────────────────────────────────

    function _createSingleInBatch(
        address recipient,
        address asset,
        uint256 rate,
        uint256 duration,
        bool enableYield,
        uint256[] memory streamIds,
        uint256 idx
    ) internal {
        if (recipient == address(0)) revert ZeroAddress();
        if (rate == 0) revert ZeroRate();
        if (duration == 0) revert ZeroDuration();

        IERC20(asset).forceApprove(address(vault), rate * duration);
        streamIds[idx] = vault.createStream(msg.sender, recipient, asset, rate, duration, enableYield);
        uint256 tokenId = streamNFT.mint(recipient, streamIds[idx]);

        emit StreamOpened(streamIds[idx], tokenId, msg.sender, recipient, asset, rate, duration);
    }
}
