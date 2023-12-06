// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignatureScript.sol";

contract CheckNoSignature is SignatureScript {
    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        loadSignatures(hashData(txData));

        require(signatureOf[SENDER].length == 0, "Already signed!");
    }
}
