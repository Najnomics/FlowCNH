// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFlowCNH.sol";

/// @title FlowCNHSponsorManager — Manages Conflux Fee Sponsorship for gasless claim() calls
/// @notice Programmatically configures SponsorWhitelistControl so that workers never need CFX
///         to withdraw their streamed payments. Sponsor balance is replenished from protocol revenue.
contract FlowCNHSponsorManager is Ownable {
    ISponsorWhitelistControl public constant SPONSOR_CONTROL =
        ISponsorWhitelistControl(0x0888000000000000000000000000000000000001);

    /// @notice Gas upper bound per sponsored transaction (in Drip)
    uint256 public gasUpperBound;

    event SponsorshipSet(address indexed contractAddr, uint256 gasFund, uint256 storageFund);
    event WhitelistUpdated(address indexed contractAddr, uint256 count);
    event GasUpperBoundUpdated(uint256 newBound);

    error InsufficientFunds();

    constructor(address _owner, uint256 _gasUpperBound) Ownable(_owner) {
        gasUpperBound = _gasUpperBound;
    }

    /// @notice Set gas sponsorship for a FlowCNH contract
    /// @param contractAddr The contract to sponsor (StreamVault)
    function sponsorGas(address contractAddr) external payable onlyOwner {
        if (msg.value == 0) revert InsufficientFunds();
        SPONSOR_CONTROL.setSponsorForGas{value: msg.value}(contractAddr, gasUpperBound);
        emit SponsorshipSet(contractAddr, msg.value, 0);
    }

    /// @notice Set storage collateral sponsorship for a FlowCNH contract
    function sponsorStorage(address contractAddr) external payable onlyOwner {
        if (msg.value == 0) revert InsufficientFunds();
        SPONSOR_CONTROL.setSponsorForCollateral{value: msg.value}(contractAddr);
        emit SponsorshipSet(contractAddr, 0, msg.value);
    }

    /// @notice Whitelist all users (zero address = everyone) for a contract
    /// @param contractAddr The contract to whitelist all users for
    function whitelistAll(address contractAddr) external onlyOwner {
        address[] memory addrs = new address[](1);
        addrs[0] = address(0); // zero address = all users sponsored
        SPONSOR_CONTROL.addPrivilegeByAdmin(contractAddr, addrs);
        emit WhitelistUpdated(contractAddr, 1);
    }

    /// @notice Whitelist specific addresses for a contract
    function whitelistAddresses(address contractAddr, address[] calldata addresses) external onlyOwner {
        SPONSOR_CONTROL.addPrivilegeByAdmin(contractAddr, addresses);
        emit WhitelistUpdated(contractAddr, addresses.length);
    }

    /// @notice Remove addresses from whitelist
    function removeFromWhitelist(address contractAddr, address[] calldata addresses) external onlyOwner {
        SPONSOR_CONTROL.removePrivilegeByAdmin(contractAddr, addresses);
    }

    /// @notice Update the gas upper bound for future sponsorship
    function setGasUpperBound(uint256 _bound) external onlyOwner {
        gasUpperBound = _bound;
        emit GasUpperBoundUpdated(_bound);
    }

    /// @notice Check current gas sponsor balance for a contract
    function getGasSponsorBalance(address contractAddr) external view returns (uint256) {
        return SPONSOR_CONTROL.getSponsoredBalanceForGas(contractAddr);
    }

    /// @notice Check if a user is whitelisted for gas sponsorship
    function isWhitelisted(address contractAddr, address user) external view returns (bool) {
        return SPONSOR_CONTROL.isWhitelisted(contractAddr, user);
    }

    /// @notice Allow contract to receive CFX for sponsorship funding
    receive() external payable {}
}
