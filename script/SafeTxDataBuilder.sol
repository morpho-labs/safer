// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SignatureDecoder} from "safe/common/SignatureDecoder.sol";
import {GnosisSafe, Enum} from "safe/GnosisSafe.sol";

import "forge-std/console2.sol";
import "forge-std/Script.sol";

contract SafeTxDataBuilder is Script, SignatureDecoder {
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

    string ROOT = vm.projectRoot();
    string SIGNATURES_DIR = string.concat(ROOT, "/signatures/");
    string SIGNATURES_FILE = string.concat(SIGNATURES_DIR, "signatures.txt");
    string DATA_FILE = string.concat(SIGNATURES_DIR, "data.txt");
    bytes NEWLINE_CHAR = bytes("\n");

    GnosisSafe immutable SAFE;

    constructor(address payable safe) {
        SAFE = GnosisSafe(safe);
    }

    function loadData() internal view returns (bytes memory) {
        bytes memory rawData = bytes(vm.readFile(DATA_FILE));
        uint256 rawDataLength = rawData[rawData.length - 1] == NEWLINE_CHAR[0] ? rawData.length - 1 : rawData.length;

        assembly {
            mstore(rawData, rawDataLength)
        }

        return vm.parseBytes(string(rawData));
    }

    function loadSafeTxData() internal returns (SafeTxData memory txData) {
        txData.to = vm.envAddress("TO");
        txData.value = vm.envOr("VALUE", uint256(0));
        txData.data = loadData();
        txData.operation = Enum.Operation(vm.envOr("OPERATION", uint256(0)));
        txData.safeTxGas = 0;
        txData.baseGas = 0;
        txData.gasPrice = 0;
        txData.gasToken = address(0); // ETH
        txData.refundReceiver = payable(address(0)); // tx.origin
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
