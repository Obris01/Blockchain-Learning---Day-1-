// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;

    address user = address(1);

    function setUp() public {
        token = new MyToken();
    }

    function testTransfer() public {
        token.transfer(user, 100 ether);
        assertEq(token.balanceOf(user), 100 ether);
    }

    function testAllowanceAndTransferFrom() public {
    address spender = address(2);

    token.approve(spender, 200 ether);

    vm.prank(spender);
    token.transferFrom(address(this), spender, 200 ether);

    assertEq(token.balanceOf(spender), 200 ether);
    }

}
