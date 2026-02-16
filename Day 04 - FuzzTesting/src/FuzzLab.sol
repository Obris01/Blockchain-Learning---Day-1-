// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

contract FuzzLab {
    uint256 public value;

    function setValue(uint256 _value) public {
        require(_value < 100, "Too large");
        value = _value;
    }
}
