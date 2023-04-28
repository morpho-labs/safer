# Safer

## Tutorial: sign data

1. Put the data to sign in `/signatures/data.txt`
2. To sign the data with a Ledger, run:
	```bash
	cast wallet sign $(cat signatures/data.txt) --ledger > signatures/{id}.txt
	```
	Where `{id}` is your signature index (the index of the address used to sign in the array of owners of the Safe).
	Keep the signed data or send it to the signer that will execute the transaction on the Safe.

## Tutorial: batch signatures and execute transaction

1. Populate your `.env` file as described in `.env.example`.
1. The data to sign should be put in `/signatures/data.txt`.
2. Each required signer must sign the data. Signatures must be put in `/signature/0.txt`, `/signature/1.txt`, etc.
3. To send the transaction to the Safe with a Ledger, run:
	```bash
	forge script script/BatchSignaturesAndExecuteOnSafe.s.sol --ledger --broadcast --rpc-url $RPC_URL
	```
4. Approve the transaction on your Ledger.
