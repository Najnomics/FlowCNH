// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/StreamVault.sol";
import "../src/FlowCNHRouter.sol";
import "../src/StreamNFT.sol";
import "../src/DForceAdapter.sol";
import "../src/FlowCNHSponsorManager.sol";

/// @title Deploy — Full deployment script for FlowCNH protocol
/// @notice Deploys all contracts to Conflux eSpace and configures permissions
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address treasury = deployer; // Use deployer as initial treasury

        uint256 protocolFeeBps = vm.envUint("PROTOCOL_FEE_BPS");
        uint256 disputeWindowSeconds = vm.envUint("DISPUTE_WINDOW_SECONDS");
        uint256 gasUpperBound = 10_000_000 gwei; // 10M GDrip upper bound

        console.log("Deployer:", deployer);
        console.log("Protocol Fee (bps):", protocolFeeBps);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy StreamNFT
        StreamNFT streamNFT = new StreamNFT(deployer);
        console.log("StreamNFT deployed:", address(streamNFT));

        // 2. Deploy DForceAdapter
        DForceAdapter dForceAdapter = new DForceAdapter(deployer);
        console.log("DForceAdapter deployed:", address(dForceAdapter));

        // 3. Deploy StreamVault
        StreamVault vault = new StreamVault(
            deployer,
            treasury,
            protocolFeeBps,
            disputeWindowSeconds
        );
        console.log("StreamVault deployed:", address(vault));

        // 4. Deploy FlowCNHRouter
        FlowCNHRouter router = new FlowCNHRouter(
            deployer,
            address(vault),
            address(streamNFT)
        );
        console.log("FlowCNHRouter deployed:", address(router));

        // 5. Deploy SponsorManager
        FlowCNHSponsorManager sponsorManager = new FlowCNHSponsorManager(deployer, gasUpperBound);
        console.log("SponsorManager deployed:", address(sponsorManager));

        // 6. Configure permissions
        vault.setRouter(address(router));
        vault.setYieldAdapter(address(dForceAdapter));
        streamNFT.setRouter(address(router));
        dForceAdapter.setVault(address(vault));

        // 7. Add supported assets
        address axcnh = vm.envAddress("AXCNH_ADDRESS");
        address usdt0 = vm.envAddress("USDT0_ADDRESS");

        if (axcnh != address(0)) {
            vault.setSupportedAsset(axcnh, true);
            console.log("AxCNH supported:", axcnh);
        }
        if (usdt0 != address(0)) {
            vault.setSupportedAsset(usdt0, true);
            console.log("USDT0 supported:", usdt0);
        }

        // 8. Configure dForce iTokens (if available)
        address iTokenAxCNH = vm.envOr("DFORCE_ITOKEN_AXCNH", address(0));
        if (iTokenAxCNH != address(0)) {
            dForceAdapter.setIToken(axcnh, iTokenAxCNH);
            console.log("dForce iToken for AxCNH:", iTokenAxCNH);
        }

        vm.stopBroadcast();

        // Output deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("StreamNFT:", address(streamNFT));
        console.log("DForceAdapter:", address(dForceAdapter));
        console.log("StreamVault:", address(vault));
        console.log("FlowCNHRouter:", address(router));
        console.log("SponsorManager:", address(sponsorManager));
    }
}
