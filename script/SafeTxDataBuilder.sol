// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SignatureDecoder} from "safe/common/SignatureDecoder.sol";
import {GnosisSafe, Enum} from "safe/GnosisSafe.sol";

import "forge-std/console2.sol";
import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

contract SafeTxDataBuilder is Script, SignatureDecoder {
    using stdJson for string;

    struct SafeTxData {
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

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;
    bytes internal constant NEWLINE_CHAR = bytes("\n");
    uint256 internal constant SIGNATURE_LENGTH = 130;

    string internal ROOT = vm.projectRoot();
    string internal SIGNATURES_DIR = string.concat(ROOT, "/data/");

    string internal TX_FILE = string.concat(SIGNATURES_DIR, "tx.json");
    string internal HASH_DATA_FILE = string.concat(SIGNATURES_DIR, "hashData.txt");
    string internal SIGNATURES_FILE = string.concat(SIGNATURES_DIR, "signatures.txt");

    GnosisSafe immutable SAFE;

    constructor(address payable safe) {
        SAFE = GnosisSafe(safe);
    }

    function loadSafeTxData() internal returns (SafeTxData memory txData) {
        string memory json = vm.readFile(TX_FILE);

        txData.to = json.readAddress("$.to");
        txData.value = json.readUint("$.value");
        txData.data = json.readBytes("$.data");
        txData.operation = Enum.Operation(json.readUint("$.operation"));
        txData.safeTxGas = json.readUint("$.safeTxGas");
        txData.baseGas = json.readUint("$.baseGas");
        txData.gasPrice = json.readUint("$.gasPrice");
        txData.gasToken = json.readAddress("$.gasToken");
        txData.refundReceiver = payable(json.readAddress("$.refundReceiver"));
    }

    function hashData(SafeTxData memory txData) internal view returns (bytes32) {
        bytes32 safeTxHash = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                txData.to,
                txData.value,
                keccak256(txData.data),
                txData.operation,
                txData.safeTxGas,
                txData.baseGas,
                txData.gasPrice,
                txData.gasToken,
                txData.refundReceiver,
                SAFE.nonce()
            )
        );

        bytes memory txHashData = abi.encodePacked(bytes1(0x19), bytes1(0x01), SAFE.domainSeparator(), safeTxHash);

        return keccak256(txHashData);
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
