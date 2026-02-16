// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasLabV1 {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}
//!@ dev this is not what we require please setup real foundry tests.
