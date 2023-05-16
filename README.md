# Safer

## Getting Started

- Install [Foundry](https://github.com/foundry-rs/foundry).
- Run `make` to initialize the repository.
- Create a `.env` file from the template [`.env.example`](./.env.example) file.
  - Use the environment variable `SAFE_NONCE` to override a transaction's nonce. Remove it to use the default, latest Safe nonce. Leave it blank to use nonce 0.
  - Use the environment variable `FOUNDRY_ETH_RPC_URL` to customize the RPC endpoint used. This is useful to interact with a Safe deployed on another chain than Ethereum mainnet (the default one).

### Build a Safe tx

- Run `make tx` and follow the steps to create a Safe transaction using [create-safe-tx](https://github.com/morpho-labs/create-safe-tx); OR
- Put the transaction's raw data in `data/tx.json`

### Sign a Safe tx

1. Hash the transaction's raw data: `make hash`
2. To sign the data with a Ledger, run: `make sign:ledger`
3. Share the content of `data/signatures.txt` with the signer who will execute the transaction on the Safe

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
  "value": "0", // The tx value (in ETH), must be a string
  "data": "0x", // The raw tx data, must start with 0x
  "operation": 0, // 0 for a call, 1 for a delegatecall
  "safeTxGas": 0,
  "baseGas": 0,
  "gasPrice": 0,
  "gasToken": "0x0000000000000000000000000000000000000000", // Indicates the tx will consume the chain's default gas token (ETH on mainnet)
  "refundReceiver": "0x0000000000000000000000000000000000000000" // Indicates the tx's refund receiver will be the address executing the tx
}
```
