// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "safe/GnosisSafe.sol";

contract BatchSignaturesAndExecuteOnSafe is Script {
    // Avoid stack too deep error.
    struct TxData {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        bytes signatures;
    }

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/signatures/");

        uint256 nbOfSignatures = 2; // TODO: automatically fetch the number of signatures?
        TxData memory txData;

        // Build signatures payload.
        for (uint256 i; i < nbOfSignatures; i++) {
            txData.signatures =
                bytes.concat(txData.signatures, vm.parseBytes(vm.readFile(string.concat(path, vm.toString(i), ".txt"))));
        }

        // Fetch Safe contract.
        GnosisSafe safe = GnosisSafe(payable(vm.envAddress("SAFE")));

        // Build tx data.
        txData.to = vm.envAddress("TO");
        txData.value = 0;
        txData.data = vm.parseBytes(vm.readFile(string.concat(path, "data.txt")));
        txData.operation = Enum.Operation.Call;
        txData.safeTxGas = 0;
        txData.baseGas = 0;
        txData.gasPrice = 0;
        txData.gasToken = address(0); // ETH
        txData.refundReceiver = payable(address(0)); // txData.origin

        // Execute tx.
        vm.broadcast(vm.envAddress("SENDER"));
        safe.execTransaction(
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
}
