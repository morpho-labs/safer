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

    function loadSignatures() internal view returns (bytes[] memory signatures) {
        signatures = new bytes[](THRESHOLD);

        string memory signature;
        for (uint256 i; i < THRESHOLD; ++i) {
            signature = vm.readLine(SIGNATURES_FILE);
            require(
                bytes(signature).length > 0,
                string.concat(
                    "Not enough signatures (found: ", vm.toString(i), "; expected: ", vm.toString(THRESHOLD), ")"
                )
            );

            signatures[i] = vm.parseBytes(signature);
        }
    }
}
