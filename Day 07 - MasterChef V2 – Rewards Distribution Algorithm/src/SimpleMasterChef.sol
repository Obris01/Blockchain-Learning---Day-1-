// Single pool
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleMasterChef {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;  

    uint256 public rewardPerBlock;
    uint256 public lastRewardBlock;
    uint256 public accRewardPerShare; // scaled by 1e12
    uint256 public totalStaked;  // @Obris01 great, state vatiables are well defined and named

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => UserInfo) public userInfo; // @Obris01 good, user info is stored in a mapping
    // possible improvements: we can now add names to mapping, field might be more descriptive, but it's not a big deal
    // e.g mapping(address userAddress => UserInfo userInfo) 

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


    // @Obris01 great, the updatePool function is well implemented and correctly updates the reward variables based on the number of blocks that have passed since the last update. 
    // It also handles the case where there are no staked tokens to avoid division by zero.
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


    // @Obris01 great, the deposit function correctly updates the user's staked amount and reward debt after transferring the stake tokens from the user to the contract. 
    // It also calculates and transfers any pending rewards to the user before updating their stake.
    // @Obris01 why is it important to transfer first before upadating the balance here, answer this in your journal
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

    // @Obris01 great, the withdraw function correctly checks if the user has enough staked tokens to withdraw, updates the pool, calculates and transfers any pending rewards to the user, and then updates the user's staked amount and reward debt after transferring the stake tokens back to the user.
    // Possible issues, this does not follow the Check-Effects-Interactions pattern, which can lead to reentrancy vulnerabilities.
    // To fix this, we should update the user's staked amount and reward debt before transferring the rewards and stake tokens.
    // I see you did that for the stake tokens, but not for the rewards, you should update the reward debt before transferring the rewards to prevent reentrancy attacks.

    //@Obris01: gastip user.amount is read multiple times, we can optimize this by storing it in a local variable to save gas.
    // e.g uint256 userAmount = user.amount; and then use userAmount instead of user.amount in the calculations. This will reduce the number of storage reads and save gas.
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

    // @Obris01 great, the pendingReward function correctly calculates the pending rewards for a user based on their staked amount and the accumulated reward per share.
    // memory read here is fine since, so no further gas optimization needed

        function pendingReward(address _user) external view returns (uint256)
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


    // other observations: possible improvements

    // 1. We can add an emergencyWithdraw function that allows users to withdraw their staked tokens without caring about rewards in case of an emergency. This can be useful in case of a bug or an attack on the contract.
    // 2. We can add a function to allow the owner to update the reward per block, which can be useful to adjust the rewards based on market conditions or to incentivize users to stake more.
    // 3. we can allow users claim their rewards without having to deposit or withdraw, this can be useful for users who want to claim their rewards without changing their staked amount.
    // 4. We can add a function to allow users to view their staked amount and pending rewards without having to call the pendingReward function, this can be useful for users who want to quickly check their rewards without having to calculate them.
    
}