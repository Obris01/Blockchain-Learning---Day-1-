// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("RGTTOKEN", "RGT") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

// Name: "RGTTOKEN"

// Symbol: "RGT"

// Initial Supply: 1,000,000