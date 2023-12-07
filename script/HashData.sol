// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeTxScript.sol";

contract HashData is SafeTxScript {
    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        vm.writeFile(HASH_DATA_FILE, vm.toString(hashData(txData)));
    }
}
