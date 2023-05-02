// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QuickSort} from "./libraries/QuickSort.sol";
import {SafeTxDataBuilder, Enum} from "./SafeTxDataBuilder.sol";

contract ExecTransaction is SafeTxDataBuilder {
    using QuickSort for address[];

    mapping(address => bytes) signatureOf;

    constructor() SafeTxDataBuilder(payable(vm.envAddress("SAFE"))) {}

    function run() public {
        SafeTxData memory txData = loadSafeTxData();
        bytes[] memory signatures = loadSignatures();

        bytes32 dataHash = hashData(txData);
        address[] memory signers = new address[](signatures.length);
        for (uint256 i; i < signatures.length; i++) {
            (address signer, bytes32 r, bytes32 s, uint8 v) = decode(dataHash, signatures[i]);

            signers[i] = signer;
            signatureOf[signer] = abi.encodePacked(r, s, v + 4);
        }

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

    function loadSignatures() internal returns (bytes[] memory signatures) {
        string[] memory cmd = new string[](2);
        cmd[0] = "cat";
        cmd[1] = SIGNATURES_FILE;

        bytes memory res = vm.ffi(cmd); // TODO: use vm.readFile

        // If the file only contains a single signature, ffi converts it to bytes and can be used as is.
        if (res.length == 32) {
            signatures = new bytes[](1);
            signatures[0] = res;
        } else {
            // Otherwise, each signature is (2 bytes 0x prefix + 64 bytes data =) 66 bytes long and suffixed by 1 byte of newline character.
            uint256 nbSignatures = (res.length + 1) / 67; // The last 1 byte newline character is trimmed by ffi.
            signatures = new bytes[](nbSignatures);

            for (uint256 i; i < nbSignatures; ++i) {
                uint256 start = i * 67 + 2; // Don't read the first 2 bytes of 0x prefix.

                bytes memory signature = new bytes(64);
                for (uint256 j; j < 64; ++j) {
                    signature[j] = res[start + j];
                }

                signatures[i] = vm.parseBytes(string(signature));
            }
        }
    }
}
