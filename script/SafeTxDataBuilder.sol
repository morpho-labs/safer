// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SignatureDecoder} from "../lib/safe-contracts/contracts/common/SignatureDecoder.sol";
import {Safe, Enum} from "../lib/safe-contracts/contracts/Safe.sol";

import "../lib/forge-std/src/console2.sol";
import "../lib/forge-std/src/StdJson.sol";
import "../lib/forge-std/src/Script.sol";

/// @dev Warning: keys must be ordered alphabetically.
struct SafeTxData {
    uint256 baseGas;
    bytes data;
    uint256 gasPrice;
    address gasToken;
    Enum.Operation operation;
    address payable refundReceiver;
    uint256 safeTxGas;
    address to;
    uint256 value;
}

struct SafeTx {
    SafeTxData data;
    bytes signatures;
}

contract SafeTxDataBuilder is Script, SignatureDecoder {
    using stdJson for string;

    string internal ROOT = vm.projectRoot();
    string internal SIGNATURES_DIR = string.concat(ROOT, "/data/");

    string internal TX_FILE = string.concat(SIGNATURES_DIR, "tx.json");
    string internal HASH_DATA_FILE = string.concat(SIGNATURES_DIR, "hashData.txt");
    string internal SIGNATURES_FILE = string.concat(SIGNATURES_DIR, "signatures.txt");

    Safe SAFE;
    address internal SENDER;
    uint256 internal NONCE;
    uint256 internal THRESHOLD;
    bytes32 internal DOMAIN_SEPARATOR;

    function setUp() public {
        SENDER = vm.envAddress("SENDER");
        SAFE = Safe(payable(vm.envAddress("SAFE")));

        NONCE = vm.envOr("SAFE_NONCE", SAFE.nonce());
        THRESHOLD = SAFE.getThreshold();
        DOMAIN_SEPARATOR = SAFE.domainSeparator();
    }

    function loadSafeTxData() internal view returns (SafeTxData memory txData) {
        return abi.decode(vm.parseJson(vm.readFile(TX_FILE)), (SafeTxData));
    }

    function hashData(SafeTxData memory txData) internal view returns (bytes32) {
        return SAFE.getTransactionHash(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.safeTxGas,
            txData.baseGas,
            txData.gasPrice,
            txData.gasToken,
            txData.refundReceiver,
            NONCE
        );
    }

    function decode(bytes32 dataHash, bytes memory signature)
        internal
        pure
        returns (address signer, bytes32 r, bytes32 s, uint8 v)
    {
        (v, r, s) = signatureSplit(signature, 0);

        signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
    }
}
