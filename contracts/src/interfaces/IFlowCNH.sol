// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStreamVault {
    enum StreamStatus { Active, Paused, Cancelled, Completed }

    struct StreamInfo {
        address sender;
        address recipient;
        address asset;
        uint256 ratePerSecond;
        uint256 startTime;
        uint256 stopTime;
        uint256 lastClaimTime;
        uint256 totalDeposited;
        uint256 totalClaimed;
        StreamStatus status;
        bool yieldEnabled;
    }

    event StreamCreated(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        address asset,
        uint256 ratePerSecond,
        uint256 startTime,
        uint256 stopTime,
        uint256 deposit
    );
    event Claimed(uint256 indexed streamId, address indexed recipient, uint256 amount);
    event StreamPaused(uint256 indexed streamId);
    event StreamResumed(uint256 indexed streamId);
    event StreamCancelled(uint256 indexed streamId, uint256 returnedToSender, uint256 claimedByRecipient);
    event YieldHarvested(uint256 indexed streamId, uint256 yieldAmount, uint256 recipientShare, uint256 protocolShare);

    function createStream(
        address sender,
        address recipient,
        address asset,
        uint256 ratePerSecond,
        uint256 duration,
        bool enableYield
    ) external returns (uint256 streamId);

    function claim(uint256 streamId) external;
    function claimableBalance(uint256 streamId) external view returns (uint256);
    function pauseStream(uint256 streamId) external;
    function resumeStream(uint256 streamId) external;
    function cancelStream(uint256 streamId) external;
    function getStream(uint256 streamId) external view returns (StreamInfo memory);
}

interface IDForceAdapter {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external returns (uint256);
    function balanceOf(address asset) external view returns (uint256);
    function harvest(address asset) external returns (uint256 yieldEarned);
}

interface ISponsorWhitelistControl {
    function setSponsorForGas(address contractAddr, uint256 upperBound) external payable;
    function setSponsorForCollateral(address contractAddr) external payable;
    function addPrivilegeByAdmin(address contractAddr, address[] memory addresses) external;
    function removePrivilegeByAdmin(address contractAddr, address[] memory addresses) external;
    function getSponsorForGas(address contractAddr) external view returns (address);
    function getSponsoredBalanceForGas(address contractAddr) external view returns (uint256);
    function getSponsoredGasFeeUpperBound(address contractAddr) external view returns (uint256);
    function isWhitelisted(address contractAddr, address user) external view returns (bool);
}
