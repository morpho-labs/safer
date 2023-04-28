# Safer

## Getting Started

- Install [Foundry](https://github.com/foundry-rs/foundry).
- Run `make` to initialize the repository.
- Create a `.env` file from the template [`.env.example`](./.env.example) file.

You can customize the RPC url used in [`foundry.tml`](./foundry.toml) under the `rpc_endpoint` section. This is useful if your Safe is not deployed on mainnet (which is the default chain used).

### Sign a Safe tx

1. Put the transaction's raw data in `signatures/tx.json`
	- Using the zero address in place of `gasToken` indicates that the tx will consume the chain's default gas token (ETH on mainnet)
	- Using the zero address in place of `refundReceiver` indicates that the tx's refund receiver will be the address executing the tx
2. Hash the transaction's raw data: `make hash`
3. To sign the data with a Ledger, run: `make sign:ledger`
4. Share the content of `signatures.txt` with the signer who will execute the transaction on the Safe.

## Batch signatures and execute transaction

1. Make at least `threshold` signatures are available in `/signatures/signatures.txt`, each one per line
2. To execute the transaction on the Safe with a Ledger, run: `make exec:ledger`
