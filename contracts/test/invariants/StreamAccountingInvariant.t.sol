// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/StreamVault.sol";
import "../../src/FlowCNHRouter.sol";
import "../../src/StreamNFT.sol";
import "../FlowCNHStream.t.sol";

/// @title StreamAccountingInvariant — Invariant tests for stream accounting correctness
/// @notice Ensures that stream accounting remains consistent under all state transitions
contract StreamAccountingInvariant is Test {
    StreamVault public vault;
    FlowCNHRouter public router;
    StreamNFT public streamNFT;
    MockERC20 public axcnh;

    address public owner = address(this);
    address public employer = makeAddr("employer");
    address public worker = makeAddr("worker");
    address public treasury = makeAddr("treasury");

    uint256 constant RATE = 0.01 ether;
    uint256 constant DURATION = 30 days;
    uint256 constant DEPOSIT = RATE * DURATION;

    function setUp() public {
        axcnh = new MockERC20("AxCNH", "AxCNH");
        vault = new StreamVault(owner, treasury, 2000, 1 days);
        streamNFT = new StreamNFT(owner);
        router = new FlowCNHRouter(owner, address(vault), address(streamNFT));

        vault.setRouter(address(router));
        vault.setSupportedAsset(address(axcnh), true);
        streamNFT.setRouter(address(router));

        axcnh.mint(employer, DEPOSIT * 100);

        // Create a stream for invariant testing
        vm.startPrank(employer);
        axcnh.approve(address(router), DEPOSIT);
        router.createStream(worker, address(axcnh), RATE, DURATION, false);
        vm.stopPrank();

        targetContract(address(vault));
    }

    /// @notice claimable + claimed should never exceed deposited
    function invariant_claimablePlusClaimedLteDeposit() public view {
        IStreamVault.StreamInfo memory info = vault.getStream(1);
        uint256 claimable = vault.claimableBalance(1);
        assertTrue(info.totalClaimed + claimable <= info.totalDeposited);
    }

    /// @notice stream with status Active should have non-zero rate
    function invariant_activeStreamHasRate() public view {
        IStreamVault.StreamInfo memory info = vault.getStream(1);
        if (uint256(info.status) == uint256(IStreamVault.StreamStatus.Active)) {
            assertTrue(info.ratePerSecond > 0);
        }
    }
}
