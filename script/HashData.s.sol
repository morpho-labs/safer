// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTxDataBuilder} from "./SafeTxDataBuilder.sol";

contract HashData is SafeTxDataBuilder {
    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        bytes32 dataHash = hashData(txData);

        vm.writeFile(HASH_DATA_FILE, vm.toString(dataHash));
    }
}
