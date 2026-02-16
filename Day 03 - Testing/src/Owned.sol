// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function onlyOwnerFunction() external view returns (bool) {
        require(msg.sender == owner, "Not owner");
        return true;
    }
}
