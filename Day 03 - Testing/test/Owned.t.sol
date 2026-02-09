// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Owned.sol";

contract OwnedTest is Test {
    Owned owned;
    address user = address(1);

    function setUp() public {
        owned = new Owned();
    }

    function testOwnerIsSetInConstructor() public view {
        assertEq(owned.owner(), address(this));
    }

    function testOwnerCanCallRestrictedFunction() public view {
        bool result = owned.onlyOwnerFunction();
        assertTrue(result);
    }
// Commenting out the Negative testing.
    // function testNonOwnerCanNotCallRestrictedFunction() public {
    //     vm.prank(user);
    //     vm.expectRevert("Not Owner");
    //     owned.onlyOwnerFunction();
    // }
}