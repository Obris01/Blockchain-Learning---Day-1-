// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FuzzLab.sol";
import "forge-std/console.sol";

contract FuzzLabTest is Test {
    FuzzLab fuzzLab;

    function setUp() public {
        fuzzLab = new FuzzLab();
    }

    function testFuzz_SetValue(uint256 randomValue) public {
        console.log("Random value:", randomValue);
        fuzzLab.setValue(randomValue);
        assertEq(fuzzLab.value(), randomValue);

        // vm.assume(randomValue > 0);

        // fuzzLab.setValue(randomValue);
        // assertTrue(fuzzLab.value() > 0);
    }
}
