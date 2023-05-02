# Safer

## Getting Started

- Install [Foundry](https://github.com/foundry-rs/foundry).
- Run `make` to initialize the repository.
- Create a `.env` file from the template [`.env.example`](./.env.example) file.

You can customize the RPC url used in [`foundry.tml`](./foundry.toml) under the `rpc_endpoint` section. This is useful if your Safe is not deployed on mainnet (which is the default chain used).

### Sign a Safe tx

1. Put the transaction's raw data in `data/tx.json`
2. Hash the transaction's raw data: `make hash`
3. To sign the data with a Ledger, run: `make sign:ledger`
4. Share the content of `data/signatures.txt` with the signer who will execute the transaction on the Safe

### Batch signatures and execute transaction

1. Make sure at least `threshold` signatures are available in `data/signatures.txt`, each one per line
2. To execute the transaction on the Safe with a Ledger, run: `make exec:ledger`

## Advanced options

### Wallet support

With `make sign` & `make exec`, one can also use any other wallet provider available with `cast`:
- `make cmd:interactive` to input the private key to the command prompt
- `make cmd:ledger` to use a Ledger
- `make cmd:trezor` to use a Trezor
- `make cmd:keystore` to use a keystore
- `make cmd:"private-key 0x..."` if you really want to save your private key to your shell's history...

### Transaction details

```json
{
    "to": "0x0000000000000000000000000000000000000000",
    "value": 0,
    "data": "0x", // The raw tx data
    "operation": 0, // 0 for a call, 1 for a delegatecall
    "safeTxGas": 0,
    "baseGas": 0,
    "gasPrice": 0,
    "gasToken": "0x0000000000000000000000000000000000000000", // Indicates the tx will consume the chain's default gas token (ETH on mainnet)
    "refundReceiver": "0x0000000000000000000000000000000000000000" // Indicates the tx's refund receiver will be the address executing the tx
}
```
