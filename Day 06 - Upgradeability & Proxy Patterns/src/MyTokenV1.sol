// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyTokenV1 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("UpgradeableToken", "UTK");
        __Ownable_init(msg.sender);

        _mint(msg.sender, 1_000_000 ether);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyOwner
    {}
}