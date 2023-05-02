// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QuickSort} from "./libraries/QuickSort.sol";
import {SafeTxDataBuilder, Enum} from "./SafeTxDataBuilder.sol";
import {console2} from "forge-std/console2.sol";

contract ExecTransaction is SafeTxDataBuilder {
    using QuickSort for address[];

    // Each signature saved in data/signatures.txt is (2 bytes 0x prefix + 130 bytes data =) 132 bytes long and suffixed by 1 byte of newline character.
    uint256 internal constant SIGNATURE_LINE_LENGTH = 2 + SIGNATURE_LENGTH + 1;

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

    function loadSignatures() internal view returns (bytes[] memory signatures) {
        bytes memory res = bytes(vm.readFile(SIGNATURES_FILE));

        // If the file only contains a single signature, it's converted to bytes and can be used as is.
        if (res.length == 65) {
            signatures = new bytes[](1);
            signatures[0] = res;
        } else {
            uint256 nbSignatures = res.length / SIGNATURE_LINE_LENGTH;
            signatures = new bytes[](nbSignatures);

            for (uint256 i; i < nbSignatures; ++i) {
                uint256 start = 2 + i * SIGNATURE_LINE_LENGTH; // Don't read the first 2 bytes (0x prefix).

                bytes memory signature = new bytes(SIGNATURE_LENGTH);
                for (uint256 j; j < SIGNATURE_LENGTH; ++j) {
                    signature[j] = res[start + j];
                }

                signatures[i] = vm.parseBytes(string(signature));
            }
        }
    }
}
