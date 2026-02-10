// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasLabV1 {

    uint256 public total;
    bool public active;
    uint128 public limit;
    address public owner;

    mapping(address => uint256) public balances;

    constructor(uint128 _limit) {
        owner = msg.sender;
        limit = _limit;
        active = true;
    }


    function deposit() public payable {
        require(active == true, "Not active");

        balances[msg.sender] = balances[msg.sender] + msg.value;
        total = total + msg.value;

        if (total > limit) {
            total = limit;
        }
    }


    function withdraw(uint256 amount) public {
        require(active == true, "Not active");
        require(balances[msg.sender] >= amount, "Not enough");

        balances[msg.sender] = balances[msg.sender] - amount;

        if (total >= amount) {
            total = total - amount;
        }

        payable(msg.sender).transfer(amount);
    }


    function toggleActive() public {
        require(msg.sender == owner, "Not owner");

        if (active == true) {
            active = false;
        } else {
            active = true;
        }
    }
}
