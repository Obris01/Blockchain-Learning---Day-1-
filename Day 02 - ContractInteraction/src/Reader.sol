// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IValueStore} from "./IValueStore.sol";

contract Reader {
    function readValue(address store) external view returns (uint256) {
        return IValueStore(store).getValue();
    }

    function writeValue(address store, uint256 value) external {
        IValueStore(store).setValue(value);
    }
}
