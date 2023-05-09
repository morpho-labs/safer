// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTxDataBuilder} from "./SafeTxDataBuilder.sol";

contract HashData is SafeTxDataBuilder {
    constructor() SafeTxDataBuilder(payable(vm.envAddress("SAFE"))) {}

    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        bytes32 dataHash = SAFE.getTransactionHash(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.safeTxGas,
            txData.baseGas,
            txData.gasPrice,
            txData.gasToken,
            txData.refundReceiver,
            NONCE
        );

        vm.writeFile(HASH_DATA_FILE, vm.toString(dataHash));
    }
}
