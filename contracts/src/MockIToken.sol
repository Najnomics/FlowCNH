// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title MockIToken — Simulates a dForce Unitus iToken for testnet demos
/// @notice Accepts deposits of the underlying token and simulates 5% APY yield
///         by minting slightly more on redeem. Exchange rate grows over time.
contract MockIToken {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    IERC20 public immutable underlying_;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    /// @notice Base exchange rate (1e18 = 1:1). Grows 5% per year simulated.
    uint256 public deployTime;
    uint256 public constant INITIAL_RATE = 1e18;
    uint256 public constant APY_BPS = 500; // 5%

    constructor(string memory _name, string memory _symbol, address _underlying) {
        name = _name;
        symbol = _symbol;
        underlying_ = IERC20(_underlying);
        deployTime = block.timestamp;
    }

    function underlying() external view returns (address) {
        return address(underlying_);
    }

    function exchangeRateStored() public view returns (uint256) {
        uint256 elapsed = block.timestamp - deployTime;
        // Linear approximation: rate = 1e18 * (1 + APY * elapsed / 365 days)
        return INITIAL_RATE + (INITIAL_RATE * APY_BPS * elapsed) / (10000 * 365 days);
    }

    function exchangeRateCurrent() external returns (uint256) {
        return exchangeRateStored();
    }

    /// @notice Mint iTokens by depositing underlying
    function mint(address _recipient, uint256 _mintAmount) external {
        underlying_.safeTransferFrom(msg.sender, address(this), _mintAmount);
        uint256 rate = exchangeRateStored();
        uint256 iTokenAmount = (_mintAmount * 1e18) / rate;
        balanceOf[_recipient] += iTokenAmount;
        totalSupply += iTokenAmount;
    }

    /// @notice Redeem iTokens for underlying
    function redeem(address _from, uint256 _redeemiToken) external {
        require(balanceOf[_from] >= _redeemiToken, "insufficient iToken");
        uint256 rate = exchangeRateStored();
        uint256 underlyingAmount = (_redeemiToken * rate) / 1e18;
        balanceOf[_from] -= _redeemiToken;
        totalSupply -= _redeemiToken;
        underlying_.safeTransfer(msg.sender, underlyingAmount);
    }

    /// @notice Redeem a specific amount of underlying
    function redeemUnderlying(address _from, uint256 _redeemUnderlying) external {
        uint256 rate = exchangeRateStored();
        uint256 iTokenAmount = (_redeemUnderlying * 1e18 + rate - 1) / rate; // round up
        require(balanceOf[_from] >= iTokenAmount, "insufficient iToken");
        balanceOf[_from] -= iTokenAmount;
        totalSupply -= iTokenAmount;
        underlying_.safeTransfer(msg.sender, _redeemUnderlying);
    }
}
