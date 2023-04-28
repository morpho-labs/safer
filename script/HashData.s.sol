// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafeTxDataBuilder, console2} from "./SafeTxDataBuilder.sol";

contract HashData is SafeTxDataBuilder {
    constructor() SafeTxDataBuilder(payable(vm.envAddress("SAFE"))) {}

    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        bytes32 dataHash = hashData(txData);

        console2.logBytes32(dataHash);
    }
}
