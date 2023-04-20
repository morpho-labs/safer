// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "safe/GnosisSafe.sol";

contract BatchSignaturesAndExecuteOnSafe is Script {

    function run() public {
        uint256 nbOfSignatures = 2; // TODO: automatically fetch the number of signatures?
        bytes memory signatures;

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/signatures/");

        for (uint256 i; i < nbOfSignatures; i++) {
            signatures = bytes.concat(signatures, vm.parseBytes(vm.readFile(string.concat(path, vm.toString(i), ".txt"))));
        }

        /*
        GnosisSafe safe = GnosisSafe(payable(vm.envAddress("SAFE")));
        address to; // Multicall?
        uint256 value; // Keep 0?
        bytes memory data; // To fetch.
        Enum.Operation operation; // Call or delegatecall?
        uint256 safeTxGas; // To fetch.
        uint256 baseGas; // To fetch.
        uint256 gasPrice; // Gas price
        address gasToken = address(0); // ETH
        address payable refundReceiver = payable(address(0)); // tx.origin

        vm.broadcast();
        safe.execTransaction(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, signatures);
        */
    }
}
