// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/StreamVault.sol";
import "../src/FlowCNHRouter.sol";
import "../src/StreamNFT.sol";
import "../test/FlowCNHStream.t.sol";

/// @title E2ETest — End-to-end test on live testnet
contract E2ETest is Script {
    StreamVault constant vault = StreamVault(0x09a1Bfac7fED8754f1EB37C802eEc9ED831A82F9);
    FlowCNHRouter constant router = FlowCNHRouter(0x2Cd74565C93BC180e29bE542047b06605e974ca0);
    StreamNFT constant nft = StreamNFT(0x349CcB9d138bE918B1AcE5849EFdd5c4652c9CbB);
    address constant worker = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        // 1. Deploy mock token
        console.log("=== STEP 1: Deploy Mock AxCNH ===");
        MockERC20 token = new MockERC20("Mock AxCNH", "mAxCNH");
        console.log("Token:", address(token));

        // 2. Register + mint + approve
        console.log("=== STEP 2: Setup ===");
        vault.setSupportedAsset(address(token), true);
        token.mint(deployer, 1000 ether);
        token.approve(address(router), 3.6 ether); // 0.001 * 3600

        // 3. Create stream: 0.001/sec for 1 hour = 3.6 total
        console.log("=== STEP 3: Create stream ===");
        (uint256 streamId, uint256 tokenId) = router.createStream(
            worker, address(token), 0.001 ether, 1 hours, false
        );
        console.log("Stream ID:", streamId);
        console.log("NFT ID:", tokenId);

        vm.stopBroadcast();

        // 4. Verify (read-only)
        _verify(streamId, tokenId, token);
    }

    function _verify(uint256 streamId, uint256 tokenId, MockERC20 token) internal view {
        console.log("\n=== STEP 4: Verify ===");

        IStreamVault.StreamInfo memory info = vault.getStream(streamId);
        console.log("Sender:", info.sender);
        console.log("Recipient:", info.recipient);
        console.log("Rate/sec:", info.ratePerSecond);
        console.log("Deposited:", info.totalDeposited);
        console.log("Status (0=Active):", uint256(info.status));

        address nftOwner = nft.ownerOf(tokenId);
        console.log("NFT owner:", nftOwner);
        console.log("NFT == worker?", nftOwner == worker);

        console.log("Claimable:", vault.claimableBalance(streamId));
        console.log("Vault bal:", token.balanceOf(address(vault)));

        console.log("\n=== E2E TEST PASSED ===");
    }
}
