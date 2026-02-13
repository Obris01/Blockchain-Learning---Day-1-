// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasLabV2 {

    // 🔹 Packed into one storage slot
    address public owner; // !@dev this is 160 bits, so once you store this i leaves 96 bits of that slot empty
    uint128 public limit; // !@dev 128 bits should go into another slot
    bool public active;  // !@dev this would be packed into the second slot with 128 public limit not the first

    // 🔹 Separate slot (uint256)
    uint256 public total;  // !@dev correct

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
