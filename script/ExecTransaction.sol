// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QuickSort} from "./libraries/QuickSort.sol";

import {SafeTxDataBuilder, SafeTx, Enum} from "./SafeTxDataBuilder.sol";

contract ExecTransaction is SafeTxDataBuilder {
    using QuickSort for address[];

    address[] signers;
    bytes[] signatures;
    mapping(address => bytes) signatureOf;

    function run() public {
        SafeTx memory safeTx;
        safeTx.data = loadSafeTxData();

        loadSignatures(hashData(safeTx.data));

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
        require(
            line.length == 132,
            string.concat(
                "Malformed signature: ", string(line), " (length: ", vm.toString(line.length), "; expected: 132)"
            )
        );

        bytes memory hexSignature = new bytes(130);
        for (uint256 j; j < 130; ++j) {
            hexSignature[j] = line[j + 2];
        }

        bytes memory signature = vm.parseBytes(string(hexSignature));

        (address signer, bytes32 r, bytes32 s, uint8 v) = decode(dataHash, signature);
        require(signatureOf[signer].length == 0, string.concat("Duplicate signature: ", string(line)));

        signatureOf[signer] = abi.encodePacked(r, s, v + 4);
        signatures.push(signature);
        signers.push(signer);
    }
}
