// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MockIToken.sol";
import "../src/DForceAdapter.sol";

/// @title SetupYield — Deploy MockIToken and configure yield for testnet demo
contract SetupYield is Script {
    address constant TOKEN = 0xEA1846c7acD8A1178F86A3d4ab3Bf654daA2C275; // Mock AxCNH
    address constant ADAPTER = 0xfD8a5df577184ad156DcF5Ec7a27B7194cC8d116;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        // 1. Deploy MockIToken
        MockIToken iToken = new MockIToken("iMock AxCNH", "imAxCNH", TOKEN);
        console.log("MockIToken deployed:", address(iToken));

        // 2. Configure DForceAdapter with the iToken
        DForceAdapter(ADAPTER).setIToken(TOKEN, address(iToken));
        console.log("iToken configured in DForceAdapter");

        vm.stopBroadcast();

        // Verify
        address configuredIToken = DForceAdapter(ADAPTER).iTokens(TOKEN);
        console.log("Verify - iToken for mock AxCNH:", configuredIToken);
        console.log("Match:", configuredIToken == address(iToken));
    }
}
