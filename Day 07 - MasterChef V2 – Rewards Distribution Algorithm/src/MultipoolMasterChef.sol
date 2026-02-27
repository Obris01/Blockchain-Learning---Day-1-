// Multi pool
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MultiPoolMasterChef is Ownable {

    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    uint256 rewardPerBlock;
    uint256 public totalAllocPoint;

    struct PoolInfo {
        IERC20 stakeToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 totalStaked;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    constructor(
        address _rewardToken,
        uint256 _rewardPerBlock
    ) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
    }

    function addPool(uint256 _allocPoint, IERC20 _stakeToken) external onlyOwner 
    {
        totalAllocPoint += _allocPoint;

        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accRewardPerShare: 0,
                totalStaked: 0
            })
        ); // @Obris01 great, the addPool function correctly adds a new pool to the poolInfo array and updates the total allocation points. It also initializes the pool's reward variables and total staked amount.
    }

    // @Obris01 great, the updatePool function is well implemented and correctly updates the reward variables based on the number of blocks that have passed since the last update. 
    // It also handles the case where there are no staked tokens to avoid division by zero
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blocks = block.number - pool.lastRewardBlock;

        uint256 reward =
           (blocks * rewardPerBlock * pool.allocPoint) /
            totalAllocPoint;

        pool.accRewardPerShare +=
            (reward * 1e12) / pool.totalStaked;

        pool.lastRewardBlock = block.number;
    }

    // @Obris01, good so far
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending =
                (user.amount * pool.accRewardPerShare) / 1e12 -
                user.rewardDebt;

            rewardToken.transfer(msg.sender, pending);
        }

        pool.stakeToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        user.amount += _amount;
        pool.totalStaked += _amount;

        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) / 1e12;
    }

    // @Obris01 great, the withdraw function correctly checks if the user has enough staked tokens to withdraw, updates the pool, calculates and transfers any pending rewards to the user, and then updates the user's staked amount and reward debt after transferring the stake tokens back to the user.
    // Also, see comments in the SimpleMasterChef contract for possible improvements regarding the Check-Effects-Interactions pattern and gas optimization by storing user.amount in a local variable.
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "Not enough");

        updatePool(_pid);

        uint256 pending =
            (user.amount * pool.accRewardPerShare) / 1e12 -
            user.rewardDebt;

        rewardToken.transfer(msg.sender, pending);

        user.amount -= _amount;
        pool.totalStaked -= _amount;

        pool.stakeToken.transfer(msg.sender, _amount);

        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) / 1e12;
    }

    // @Obris01 great, the pendingReward function correctly calculates the pending rewards for a user based on their staked amount and the accumulated reward per share for the specific pool. It also accounts for any new rewards that have been accumulated since the last update of the pool.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        uint256 _accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0) 
        {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;

            _accRewardPerShare += (reward * 1e12) / pool.totalStaked;
        }

        return
            (user.amount * _accRewardPerShare) / 1e12
            - user.rewardDebt;
    }

    // other observations: possible improvements
    // see comments in the SimpleMasterChef contract for possible improvements regarding adding an emergencyWithdraw function, allowing the owner to update the reward per block, allowing users to claim their rewards without having to deposit or withdraw, and allowing users to view their staked amount and pending rewards without having to call the pendingReward function.
}