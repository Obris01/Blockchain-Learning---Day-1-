// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {MyTokenV1} from "./MyTokenV1.sol";

contract MyTokenV2 is MyTokenV1 {

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}