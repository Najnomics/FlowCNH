// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StreamVault.sol";
import "../src/FlowCNHRouter.sol";
import "../src/StreamNFT.sol";
import "../src/DForceAdapter.sol";

/// @dev Mock ERC-20 token for testing (AxCNH stand-in)
contract MockERC20 is Test {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "insufficient");
        if (allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= amount, "allowance");
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract FlowCNHStreamTest is Test {
    StreamVault public vault;
    FlowCNHRouter public router;
    StreamNFT public streamNFT;
    MockERC20 public axcnh;

    address public owner = address(this);
    address public employer = makeAddr("employer");
    address public worker = makeAddr("worker");
    address public worker2 = makeAddr("worker2");
    address public treasury = makeAddr("treasury");

    uint256 constant RATE = 0.01 ether; // 0.01 AxCNH per second
    uint256 constant DURATION = 30 days;
    uint256 constant DEPOSIT = RATE * DURATION;
    uint256 constant PROTOCOL_FEE_BPS = 2000; // 20%
    uint256 constant DISPUTE_WINDOW = 1 days;

    function setUp() public {
        axcnh = new MockERC20("AxCNH", "AxCNH");

        vault = new StreamVault(owner, treasury, PROTOCOL_FEE_BPS, DISPUTE_WINDOW);
        streamNFT = new StreamNFT(owner);
        router = new FlowCNHRouter(owner, address(vault), address(streamNFT));

        vault.setRouter(address(router));
        vault.setSupportedAsset(address(axcnh), true);
        streamNFT.setRouter(address(router));

        // Fund employer
        axcnh.mint(employer, DEPOSIT * 10);
    }

    // ─── Stream Creation ──────────────────────────────────────────────

    function test_createStream() public {
        vm.startPrank(employer);
        axcnh.approve(address(router), DEPOSIT);
        (uint256 streamId, uint256 tokenId) = router.createStream(
            worker, address(axcnh), RATE, DURATION, false
        );
        vm.stopPrank();

        assertEq(streamId, 1);
        assertEq(tokenId, 1);

        IStreamVault.StreamInfo memory info = vault.getStream(streamId);
        assertEq(info.sender, employer);
        assertEq(info.recipient, worker);
        assertEq(info.asset, address(axcnh));
        assertEq(info.ratePerSecond, RATE);
        assertEq(info.totalDeposited, DEPOSIT);
        assertEq(info.totalClaimed, 0);
        assertEq(uint256(info.status), uint256(IStreamVault.StreamStatus.Active));

        // NFT minted to worker
        assertEq(streamNFT.ownerOf(tokenId), worker);
        assertEq(streamNFT.streamRecipient(streamId), worker);
    }

    function test_createStream_revertsZeroRecipient() public {
        vm.startPrank(employer);
        axcnh.approve(address(router), DEPOSIT);
        vm.expectRevert(FlowCNHRouter.ZeroAddress.selector);
        router.createStream(address(0), address(axcnh), RATE, DURATION, false);
        vm.stopPrank();
    }

    function test_createStream_revertsZeroRate() public {
        vm.startPrank(employer);
        axcnh.approve(address(router), DEPOSIT);
        vm.expectRevert(FlowCNHRouter.ZeroRate.selector);
        router.createStream(worker, address(axcnh), 0, DURATION, false);
        vm.stopPrank();
    }

    // ─── Claiming ─────────────────────────────────────────────────────

    function test_claimableBalance_accruesOverTime() public {
        _createDefaultStream();

        // Warp 1 hour
        vm.warp(block.timestamp + 1 hours);

        uint256 claimable = vault.claimableBalance(1);
        assertEq(claimable, RATE * 1 hours);
    }

    function test_claim() public {
        _createDefaultStream();

        vm.warp(block.timestamp + 1 hours);

        uint256 expectedAmount = RATE * 1 hours;

        vm.prank(worker);
        vault.claim(1);

        assertEq(axcnh.balanceOf(worker), expectedAmount);

        IStreamVault.StreamInfo memory info = vault.getStream(1);
        assertEq(info.totalClaimed, expectedAmount);
    }

    function test_claim_multipleTimes() public {
        _createDefaultStream();

        // Claim after 1 hour
        vm.warp(1 + 1 hours);
        vm.prank(worker);
        vault.claim(1);

        uint256 bal1 = axcnh.balanceOf(worker);
        assertEq(bal1, RATE * 1 hours);

        // Claim after another hour (2 hours total from stream start)
        vm.warp(1 + 2 hours);
        vm.prank(worker);
        vault.claim(1);

        uint256 bal2 = axcnh.balanceOf(worker);
        assertEq(bal2, RATE * 2 hours);
    }

    function test_claim_fullDuration() public {
        _createDefaultStream();

        // Warp past end
        vm.warp(block.timestamp + DURATION + 1 days);

        vm.prank(worker);
        vault.claim(1);

        assertEq(axcnh.balanceOf(worker), DEPOSIT);

        IStreamVault.StreamInfo memory info = vault.getStream(1);
        assertEq(uint256(info.status), uint256(IStreamVault.StreamStatus.Completed));
    }

    function test_claim_nothingToClaim() public {
        _createDefaultStream();

        vm.expectRevert(StreamVault.NothingToClaim.selector);
        vm.prank(worker);
        vault.claim(1);
    }

    // ─── Pause / Resume ───────────────────────────────────────────────

    function test_pauseStream() public {
        _createDefaultStream();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(employer);
        vault.pauseStream(1);

        IStreamVault.StreamInfo memory info = vault.getStream(1);
        assertEq(uint256(info.status), uint256(IStreamVault.StreamStatus.Paused));

        // Accrual should freeze at 1 hour
        uint256 claimableAtPause = vault.claimableBalance(1);
        assertEq(claimableAtPause, RATE * 1 hours);

        // Warp more — claimable should NOT increase
        vm.warp(block.timestamp + 1 hours);
        assertEq(vault.claimableBalance(1), claimableAtPause);
    }

    function test_resumeStream() public {
        _createDefaultStream();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(employer);
        vault.pauseStream(1);

        vm.warp(block.timestamp + 1 hours); // paused for 1 hour

        vm.prank(employer);
        vault.resumeStream(1);

        IStreamVault.StreamInfo memory info = vault.getStream(1);
        assertEq(uint256(info.status), uint256(IStreamVault.StreamStatus.Active));
    }

    // ─── Cancellation ─────────────────────────────────────────────────

    function test_cancelStream_disputeWindow() public {
        _createDefaultStream();

        vm.warp(block.timestamp + 1 hours);

        // First call: initiate cancellation
        vm.prank(employer);
        vault.cancelStream(1);

        // Stream should still be active (dispute window started)
        IStreamVault.StreamInfo memory info = vault.getStream(1);
        assertEq(uint256(info.status), uint256(IStreamVault.StreamStatus.Active));

        // Second call before window expires: should revert
        vm.expectRevert(StreamVault.DisputeWindowActive.selector);
        vm.prank(employer);
        vault.cancelStream(1);

        // Warp past dispute window
        vm.warp(block.timestamp + DISPUTE_WINDOW + 1);

        // Now cancellation should succeed
        vm.prank(employer);
        vault.cancelStream(1);

        info = vault.getStream(1);
        assertEq(uint256(info.status), uint256(IStreamVault.StreamStatus.Cancelled));
    }

    function test_cancelStream_refundsCorrectly() public {
        _createDefaultStream();

        vm.warp(block.timestamp + 1 hours);

        // Initiate cancellation
        vm.prank(employer);
        vault.cancelStream(1);

        // Warp past dispute window
        vm.warp(block.timestamp + DISPUTE_WINDOW + 1);

        uint256 employerBefore = axcnh.balanceOf(employer);
        uint256 workerBefore = axcnh.balanceOf(worker);

        vm.prank(employer);
        vault.cancelStream(1);

        uint256 workerReceived = axcnh.balanceOf(worker) - workerBefore;
        uint256 employerRefund = axcnh.balanceOf(employer) - employerBefore;

        // Worker gets accrued, employer gets remainder
        assertTrue(workerReceived > 0);
        assertTrue(employerRefund > 0);
        assertEq(workerReceived + employerRefund, DEPOSIT);
    }

    // ─── Batch Streams ────────────────────────────────────────────────

    function test_createBatchStreams() public {
        address[] memory recipients = new address[](2);
        recipients[0] = worker;
        recipients[1] = worker2;

        uint256[] memory rates = new uint256[](2);
        rates[0] = RATE;
        rates[1] = RATE / 2;

        uint256[] memory durations = new uint256[](2);
        durations[0] = DURATION;
        durations[1] = DURATION;

        uint256 totalNeeded = (RATE * DURATION) + ((RATE / 2) * DURATION);

        vm.startPrank(employer);
        axcnh.approve(address(router), totalNeeded);
        uint256[] memory ids = router.createBatchStreams(
            recipients, address(axcnh), rates, durations, false
        );
        vm.stopPrank();

        assertEq(ids.length, 2);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);

        assertEq(streamNFT.ownerOf(1), worker);
        assertEq(streamNFT.ownerOf(2), worker2);
    }

    // ─── Stream NFT Transfer ──────────────────────────────────────────

    function test_nftTransferrable() public {
        _createDefaultStream();

        // Worker transfers NFT to worker2
        vm.prank(worker);
        streamNFT.transferFrom(worker, worker2, 1);

        assertEq(streamNFT.ownerOf(1), worker2);
        assertEq(streamNFT.streamRecipient(1), worker2);
    }

    // ─── Fuzz Tests ───────────────────────────────────────────────────

    function testFuzz_claimableNeverExceedsDeposit(uint256 elapsed) public {
        _createDefaultStream();

        elapsed = bound(elapsed, 0, DURATION * 2);
        vm.warp(block.timestamp + elapsed);

        uint256 claimable = vault.claimableBalance(1);
        assertTrue(claimable <= DEPOSIT);
    }

    function testFuzz_totalClaimedNeverExceedsDeposit(uint256 claimCount) public {
        _createDefaultStream();

        claimCount = bound(claimCount, 1, 10);
        uint256 interval = DURATION / claimCount;

        uint256 totalClaimed;
        for (uint256 i; i < claimCount; i++) {
            vm.warp(block.timestamp + interval);
            uint256 claimable = vault.claimableBalance(1);
            if (claimable > 0) {
                vm.prank(worker);
                vault.claim(1);
                totalClaimed += claimable;
            }
        }

        assertTrue(totalClaimed <= DEPOSIT);
    }

    // ─── Helpers ──────────────────────────────────────────────────────

    function _createDefaultStream() internal returns (uint256 streamId) {
        vm.startPrank(employer);
        axcnh.approve(address(router), DEPOSIT);
        (streamId,) = router.createStream(worker, address(axcnh), RATE, DURATION, false);
        vm.stopPrank();
    }
}
