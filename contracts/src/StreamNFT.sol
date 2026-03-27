// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title StreamNFT — ERC-721 representing FlowCNH stream positions
/// @notice Each active stream mints an NFT to the recipient. Transferring the NFT
///         transfers the right to claim future stream payments.
contract StreamNFT is ERC721Enumerable, Ownable {
    address public router;
    uint256 private _nextTokenId;

    mapping(uint256 => uint256) public tokenIdToStreamId;
    mapping(uint256 => uint256) public streamIdToTokenId;

    error OnlyRouter();
    error StreamAlreadyMinted(uint256 streamId);

    modifier onlyRouter() {
        if (msg.sender != router) revert OnlyRouter();
        _;
    }

    constructor(address _owner) ERC721("FlowCNH Stream", "fCNH") Ownable(_owner) {
        _nextTokenId = 1;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    /// @notice Mint a stream NFT to the recipient
    /// @param to Recipient address
    /// @param streamId The stream ID this NFT represents
    /// @return tokenId The minted token ID
    function mint(address to, uint256 streamId) external onlyRouter returns (uint256 tokenId) {
        if (streamIdToTokenId[streamId] != 0) revert StreamAlreadyMinted(streamId);

        tokenId = _nextTokenId++;
        tokenIdToStreamId[tokenId] = streamId;
        streamIdToTokenId[streamId] = tokenId;

        _safeMint(to, tokenId);
    }

    /// @notice Burn a stream NFT when a stream is cancelled or completed
    /// @param streamId The stream ID to burn
    function burn(uint256 streamId) external onlyRouter {
        uint256 tokenId = streamIdToTokenId[streamId];
        if (tokenId == 0) return;

        delete streamIdToTokenId[streamId];
        delete tokenIdToStreamId[tokenId];

        _burn(tokenId);
    }

    /// @notice Get the current owner (recipient) of a stream
    function streamRecipient(uint256 streamId) external view returns (address) {
        uint256 tokenId = streamIdToTokenId[streamId];
        if (tokenId == 0) return address(0);
        return ownerOf(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://flow-cnh.vercel.app/api/metadata/";
    }
}
