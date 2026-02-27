// Single pool
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleMasterChef {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardPerBlock;
    uint256 public lastRewardBlock;
    uint256 public accRewardPerShare; // scaled by 1e12
    uint256 public totalStaked;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => UserInfo) public userInfo;

    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _rewardPerBlock
    ) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = block.number;
    }

    function updatePool() public {
        if (block.number <= lastRewardBlock) return;

        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 blocks = block.number - lastRewardBlock;
        uint256 reward = blocks * rewardPerBlock;

        accRewardPerShare += (reward * 1e12) / totalStaked;
        lastRewardBlock = block.number;
    }

    function deposit(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        if (user.amount > 0) {
            uint256 pending =
                (user.amount * accRewardPerShare) / 1e12
                - user.rewardDebt;

            rewardToken.safeTransfer(msg.sender, pending);
        }

        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);

        user.amount += _amount;
        totalStaked += _amount;

        user.rewardDebt =
            (user.amount * accRewardPerShare) / 1e12;
    }

    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Not enough");

        updatePool();

        uint256 pending =
            (user.amount * accRewardPerShare) / 1e12
            - user.rewardDebt;

        rewardToken.transfer(msg.sender, pending);

        user.amount -= _amount;
        totalStaked -= _amount;

        stakeToken.transfer(msg.sender, _amount);

        user.rewardDebt =
            (user.amount * accRewardPerShare) / 1e12;
    }

    function pendingReward(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_user];

        uint256 _accRewardPerShare = accRewardPerShare;

        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 blocks = block.number - lastRewardBlock;
            uint256 reward = blocks * rewardPerBlock;
            _accRewardPerShare +=
                (reward * 1e12) / totalStaked;
        }

        return
            (user.amount * _accRewardPerShare) / 1e12
            - user.rewardDebt;
    }
}