// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QuickSort} from "./libraries/QuickSort.sol";
import {SafeTxDataBuilder, Enum} from "./SafeTxDataBuilder.sol";
import {console2} from "forge-std/console2.sol";

contract ExecTransaction is SafeTxDataBuilder {
    using QuickSort for address[];

    address[] signers;
    bytes[] signatures;
    mapping(address => bytes) signatureOf;

    constructor() SafeTxDataBuilder(payable(vm.envAddress("SAFE"))) {}

    function run() public {
        SafeTxData memory txData = loadSafeTxData();

        loadSignatures(hashData(txData));

        signers.sort();

        for (uint256 i; i < signers.length; ++i) {
            txData.signatures = bytes.concat(txData.signatures, signatureOf[signers[i]]);
        }

        // Execute tx.
        vm.broadcast(vm.envAddress("SENDER"));
        SAFE.execTransaction(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.safeTxGas,
            txData.baseGas,
            txData.gasPrice,
            txData.gasToken,
            txData.refundReceiver,
            txData.signatures
        );
    }

    function loadSignatures(bytes32 dataHash) internal {
        bytes memory line = bytes(vm.readLine(SIGNATURES_FILE));

        while (line.length > 0 && signatures.length < THRESHOLD) {
            parseSignature(dataHash, line);

            line = bytes(vm.readLine(SIGNATURES_FILE));
        }

        uint256 nbSignatures = signatures.length;
        require(
            nbSignatures >= THRESHOLD,
            string.concat(
                "Not enough signatures (found: ", vm.toString(nbSignatures), "; expected: ", vm.toString(THRESHOLD), ")"
            )
        );
    }

    function parseSignature(bytes32 dataHash, bytes memory line) internal {
        if (line.length != 132) {
            console2.log(
                string.concat(
                    "Malformed signature: ", string(line), " (length: ", vm.toString(line.length), "; expected: 132)"
                )
            );

            return;
        }

        bytes memory hexSignature = new bytes(130);
        for (uint256 j; j < 130; ++j) {
            hexSignature[j] = line[j + 2];
        }

        bytes memory signature = vm.parseBytes(string(hexSignature));

        (address signer, bytes32 r, bytes32 s, uint8 v) = decode(dataHash, signature);
        if (signatureOf[signer].length != 0) {
            console2.log(string.concat("Duplicate signature: ", string(line)));

            return;
        }

        signatureOf[signer] = abi.encodePacked(r, s, v + 4);
        signatures.push(signature);
        signers.push(signer);
    }
}
