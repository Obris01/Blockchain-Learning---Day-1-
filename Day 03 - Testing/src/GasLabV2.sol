// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasLabV2 {

    // 🔹 Packed into one storage slot
    address public owner;
    uint128 public limit;
    bool public active;

    // 🔹 Separate slot (uint256)
    uint256 public total;

    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier isActive() {
        require(active, "Not active");
        _;
    }

    constructor(uint128 _limit) {
        owner = msg.sender;
        limit = _limit;
        active = true;
    }

    function deposit() external payable isActive {
        uint256 balance = balances[msg.sender] + msg.value;
        balances[msg.sender] = balance;

        uint256 newTotal = total + msg.value;
        total = newTotal > limit ? limit : newTotal;
    }

    function withdraw(uint256 amount) external isActive {
        uint256 userBalance = balances[msg.sender];
        require(userBalance >= amount, "Not enough");

        balances[msg.sender] = userBalance - amount;
        total -= amount;

        // payable(msg.sender).transfer(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function toggleActive() external onlyOwner {
        active = !active;
    }
}
