// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QuickSort} from "./libraries/QuickSort.sol";

import "./SignatureScript.sol";

contract ExecTransaction is SignatureScript {
    using QuickSort for address[];

    function run() public {
        SafeTx memory safeTx;
        safeTx.data = loadSafeTxData();

        loadSignatures(hashData(safeTx.data));

        uint256 nbSignatures = signatures.length;
        require(
            nbSignatures >= THRESHOLD,
            string.concat(
                "Not enough signatures (found: ", vm.toString(nbSignatures), "; expected: ", vm.toString(THRESHOLD), ")"
            )
        );

        signers.sort();

        for (uint256 i; i < signers.length; ++i) {
            safeTx.signatures = bytes.concat(safeTx.signatures, signatureOf[signers[i]]);
        }

        // Execute tx.
        vm.broadcast(SENDER);
        SAFE.execTransaction(
            safeTx.data.to,
            safeTx.data.value,
            safeTx.data.data,
            safeTx.data.operation,
            safeTx.data.safeTxGas,
            safeTx.data.baseGas,
            safeTx.data.gasPrice,
            safeTx.data.gasToken,
            safeTx.data.refundReceiver,
            safeTx.signatures
        );
    }
}
