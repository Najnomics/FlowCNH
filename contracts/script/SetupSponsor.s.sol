// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/FlowCNHSponsorManager.sol";

/// @title SetupSponsor — Configure Fee Sponsorship for gasless claim()
/// @notice Run after deployment to fund gas sponsorship and whitelist all users
contract SetupSponsor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sponsorManager = vm.envAddress("SPONSOR_MANAGER_ADDRESS");
        address vaultAddress = vm.envAddress("NEXT_PUBLIC_VAULT_ADDRESS");
        uint256 sponsorFund = vm.envUint("SPONSOR_FUND_AMOUNT_CFX") * 1 ether;

        console.log("Setting up Fee Sponsorship...");
        console.log("SponsorManager:", sponsorManager);
        console.log("Vault:", vaultAddress);
        console.log("Fund amount:", sponsorFund);

        vm.startBroadcast(deployerPrivateKey);

        FlowCNHSponsorManager manager = FlowCNHSponsorManager(payable(sponsorManager));

        // Fund gas sponsorship for the StreamVault
        manager.sponsorGas{value: sponsorFund}(vaultAddress);

        // Whitelist all users (zero address = everyone gets sponsored)
        manager.whitelistAll(vaultAddress);

        vm.stopBroadcast();

        console.log("Fee Sponsorship configured!");
        console.log("All users whitelisted for gasless claim() on vault");
    }
}
