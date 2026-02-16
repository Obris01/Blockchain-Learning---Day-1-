// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GasLabV1.sol";
import "../src/GasLabV2.sol";

contract GasLabTest is Test {
    GasLabV1 v1;
    GasLabV2 v2;

    function setUp() public {
        v1 = new GasLabV1(10 ether);
        v2 = new GasLabV2(10 ether);

        vm.deal(address(this), 20 ether);
    }

    function testGasDepositV1() public {
        v1.deposit{value: 1 ether}();
    }

    function testGasDepositV2() public {
        v2.deposit{value: 1 ether}();
    }

    function testGasWithdrawV1() public {
        v1.deposit{value: 1 ether}();
        v1.withdraw(0.5 ether);
    }

    function testGasWithdrawV2() public {
        v2.deposit{value: 1 ether}();
        v2.withdraw(0.5 ether);
    }
}
