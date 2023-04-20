// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract BatchSignaturesAndExecuteOnSafe is Script {

    function run() public {
        uint256 nbOfSignatures = 2; // TODO: automatically fetch the number of signatures?
        bytes memory signatures;

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/signatures/");

        for (uint256 i; i < nbOfSignatures; i++) {
            signatures = bytes.concat(signatures, vm.parseBytes(vm.readFile(string.concat(path, vm.toString(i), ".txt"))));
        }

        vm.broadcast();
        // TODO: Execute the transaction on the Safe.
    }
}
