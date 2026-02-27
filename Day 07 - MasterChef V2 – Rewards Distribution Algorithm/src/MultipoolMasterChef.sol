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
        );
    }

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
}