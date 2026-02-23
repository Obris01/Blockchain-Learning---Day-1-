// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
//import "forge-std/Test.sol";
import {MyTokenV1} from "../src/MyTokenV1.sol";
import {MyTokenV2} from "../src/MyTokenV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MyTokenV1Test is Test {

    MyTokenV1 public implementation;
    MyTokenV1 public proxyToken;

    function setUp() public {
        implementation = new MyTokenV1();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(MyTokenV1.initialize.selector)
        );

        proxyToken = MyTokenV1(address(proxy));
    }

    function testInitialSupply() public view {
        assertEq(proxyToken.totalSupply(), 1_000_000 ether);
    }

    function testTransfer() public {
        bool success = proxyToken.transfer(address(1), 100 ether);
        assertTrue(success);
        //proxyToken.transfer(address(1), 100 ether);
        //assertEq(proxyToken.balanceOf(address(1)), 100 ether);
    }

    function testUpgrade() public {
    MyTokenV2 newImplementation = new MyTokenV2();

    // Upgrade via proxy
    proxyToken.upgradeToAndCall(address(newImplementation), "");

    // Now cast proxy as V2
    MyTokenV2 upgraded = MyTokenV2(address(proxyToken));

    upgraded.burn(100 ether);

    assertTrue(true);
    }
}