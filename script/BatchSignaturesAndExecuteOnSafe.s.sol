// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {QuickSort} from "./libraries/QuickSort.sol";
import {SignatureDecoder} from "safe/common/SignatureDecoder.sol";
import {GnosisSafe, Enum} from "safe/GnosisSafe.sol";

import "forge-std/console2.sol";
import "forge-std/Script.sol";

contract BatchSignaturesAndExecuteOnSafe is Script, SignatureDecoder {
    using QuickSort for address[];

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

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    string ROOT = vm.projectRoot();
    string SIGNATURES_DIR = string.concat(ROOT, "/signatures/");
    string SIGNATURES_FILE = string.concat(SIGNATURES_DIR, "signatures.txt");
    string DATA_FILE = string.concat(SIGNATURES_DIR, "data.txt");

    GnosisSafe immutable SAFE = GnosisSafe(payable(vm.envAddress("SAFE")));

    mapping(address => bytes) signatureOf;

    function run() public {
        bytes[] memory signatures = loadSignatures();

        // Build tx data.
        TxData memory txData;

        txData.to = vm.envAddress("TO");
        txData.value = 0;
        txData.data = vm.parseBytes(vm.readFile(DATA_FILE));
        txData.operation = Enum.Operation.Call;
        txData.safeTxGas = 0;
        txData.baseGas = 0;
        txData.gasPrice = 0;
        txData.gasToken = address(0); // ETH
        txData.refundReceiver = payable(address(0)); // tx.origin

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

        bytes memory res = vm.ffi(cmd);

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

    function decode(bytes32 dataHash, bytes memory signature)
        internal
        pure
        returns (address signer, bytes32 r, bytes32 s, uint8 v)
    {
        (v, r, s) = signatureSplit(signature, 0);

        signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
    }

    function hashData(TxData memory txData) internal view returns (bytes32) {
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
}
