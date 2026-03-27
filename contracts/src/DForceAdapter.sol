// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFlowCNH.sol";

/// @title IDForceIToken — dForce Unitus iToken interface
interface IDForceIToken {
    function mint(address _recipient, uint256 _mintAmount) external;
    function redeem(address _from, uint256 _redeemiToken) external;
    function redeemUnderlying(address _from, uint256 _redeemUnderlying) external;
    function balanceOf(address _owner) external view returns (uint256);
    function balanceOfUnderlying(address _owner) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function underlying() external view returns (address);
}

/// @title DForceAdapter — Manages dForce Unitus supply/withdraw for idle stream balances
/// @notice Routes idle AxCNH into dForce Unitus lending markets and harvests yield
contract DForceAdapter is IDForceAdapter, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Maps asset address => dForce iToken address
    mapping(address => address) public iTokens;

    /// @notice Tracks total principal supplied per asset (excludes yield)
    mapping(address => uint256) public principalSupplied;

    address public vault;

    error OnlyVault();
    error ITokenNotConfigured(address asset);
    error ZeroAmount();

    modifier onlyVault() {
        if (msg.sender != vault) revert OnlyVault();
        _;
    }

    constructor(address _owner) Ownable(_owner) {}

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /// @notice Register a dForce iToken for an asset
    function setIToken(address asset, address iToken) external onlyOwner {
        iTokens[asset] = iToken;
    }

    /// @notice Supply asset to dForce Unitus lending market
    function supply(address asset, uint256 amount) external override onlyVault {
        if (amount == 0) revert ZeroAmount();
        address iToken = iTokens[asset];
        if (iToken == address(0)) revert ITokenNotConfigured(asset);

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).forceApprove(iToken, amount);

        IDForceIToken(iToken).mint(address(this), amount);
        principalSupplied[asset] += amount;
    }

    /// @notice Withdraw asset from dForce Unitus
    function withdraw(address asset, uint256 amount) external override onlyVault returns (uint256) {
        if (amount == 0) revert ZeroAmount();
        address iToken = iTokens[asset];
        if (iToken == address(0)) revert ITokenNotConfigured(asset);

        uint256 balBefore = IERC20(asset).balanceOf(address(this));
        IDForceIToken(iToken).redeemUnderlying(address(this), amount);
        uint256 withdrawn = IERC20(asset).balanceOf(address(this)) - balBefore;

        if (principalSupplied[asset] >= withdrawn) {
            principalSupplied[asset] -= withdrawn;
        } else {
            principalSupplied[asset] = 0;
        }

        IERC20(asset).safeTransfer(msg.sender, withdrawn);
        return withdrawn;
    }

    /// @notice Get current underlying balance in dForce
    function balanceOf(address asset) external view override returns (uint256) {
        address iToken = iTokens[asset];
        if (iToken == address(0)) return 0;

        uint256 iTokenBal = IDForceIToken(iToken).balanceOf(address(this));
        uint256 exchangeRate = IDForceIToken(iToken).exchangeRateStored();
        return (iTokenBal * exchangeRate) / 1e18;
    }

    /// @notice Harvest yield earned above principal
    function harvest(address asset) external override onlyVault returns (uint256 yieldEarned) {
        address iToken = iTokens[asset];
        if (iToken == address(0)) return 0;

        // Force exchange rate update
        IDForceIToken(iToken).exchangeRateCurrent();

        uint256 iTokenBal = IDForceIToken(iToken).balanceOf(address(this));
        uint256 exchangeRate = IDForceIToken(iToken).exchangeRateStored();
        uint256 totalUnderlying = (iTokenBal * exchangeRate) / 1e18;

        if (totalUnderlying <= principalSupplied[asset]) return 0;

        yieldEarned = totalUnderlying - principalSupplied[asset];

        // Redeem the yield portion
        uint256 balBefore = IERC20(asset).balanceOf(address(this));
        IDForceIToken(iToken).redeemUnderlying(address(this), yieldEarned);
        uint256 actualYield = IERC20(asset).balanceOf(address(this)) - balBefore;

        IERC20(asset).safeTransfer(msg.sender, actualYield);
        return actualYield;
    }
}
