import { input, select } from "@inquirer/prompts";
import { Contract, FunctionFragment, getDefaultProvider, isAddress, isHexString, parseUnits, toBigInt } from "ethers";
import { TransactionType, encodeMulti, MetaTransaction, OperationType, encodeSingle } from "ethers-multisend";
import { spawnSync } from "child_process";
import { writeFileSync } from "fs";
import * as path from "path";
import { config } from "dotenv";

config();

const operationTypes = {
  Call: OperationType.Call,
  DelegateCall: OperationType.DelegateCall,
};

const trial =
  (transformer: (value: string) => string | boolean | Promise<string | boolean>, error: string) =>
  async (value: string) => {
    try {
      return (await transformer(value)) || error;
    } catch (err: any) {
      return `${error} "${value}": ${err.message}`;
    }
  };

const address = (config: { message: string; default?: string }) =>
  input({
    ...config,
    validate: trial((value) => isAddress(value), "Invalid address"),
  });

const number = (config: { message: string; min: number; default?: string }) =>
  input({
    ...config,
    validate: trial((value) => {
      const amount = parseInt(value);

      if (isNaN(amount)) return false;
      if (amount < config.min) return `Value below minimum: ${config.min}`;

      return true;
    }, "Invalid value"),
  });

(async () => {
  console.log();
  console.log("      #########################################");
  console.log("      ##         Transaction Builder         ##");
  console.log("      #########################################");

  console.log(`\n          --- Safe Transaction Options ---\n`);

  const nbTxs = parseInt(
    await number({
      message: "How many transactions do you want to batch?",
      default: "1",
      min: 1,
    })
  );
  const gasToken = await address({
    message: `With which ERC20 token do you want to pay gas? (default: ETH)`,
    default: "0x0000000000000000000000000000000000000000",
  });

  let txs: MetaTransaction[] = [];
  for (const index of new Array(nbTxs).fill(0).map((_, index) => index)) {
    console.log(`\n          --- Transaction #${(index + 1).toString().padStart(2, "0")} ---\n`);

    const prefix = `  `;

    const txType = (await select({
      message: prefix + `Type of transaction:`,
      choices: [
        { name: "Contract call", value: TransactionType.callContract },
        { name: "ERC20 transfer", value: TransactionType.transferFunds },
        { name: "ERC721/ERC1155 transfer", value: TransactionType.transferCollectible },
        { name: "Raw transaction", value: TransactionType.raw },
      ],
    })) as TransactionType;

    let to = "0x";
    let data = "0x";
    let value = "0";

    switch (txType) {
      case TransactionType.callContract:
        to = await address({ message: prefix + `Contract address` });

        const functionSelector = await input({
          message: prefix + `Function selector`,
          validate: trial((value) => !!FunctionFragment.from(`function ${value}`), "Invalid function selector"),
        });
        const fragment = FunctionFragment.from(`function ${functionSelector}`);

        const values = [];
        for (const { param, index } of fragment.inputs.map((param, index) => ({ param, index }))) {
          const value = await input({
            message: prefix + `   ${param.name || "Parameter #" + index} (${param.type})`,
            validate: (value) => {
              const process = spawnSync("cast", ["abi-encode", `function(${param.type})`, value]); // Using cast because it reads human JSON.

              const res = process.stdout.toString().trim();
              if (!isHexString(res)) return `Invalid value "${value}" for type "${param.type}"`;

              return true;
            },
          });

          values.push(value);
        }

        const subprocess = spawnSync("cast", ["calldata", fragment.format("sighash")].concat(values));

        data = subprocess.stdout.toString().trim();
        if (!isHexString(data))
          throw Error(`An error happened when encoding calldata:\n${data}\n${subprocess.stderr.toString().trim()}`);

        value = await number({
          message: prefix + `Value (ETH)`,
          default: "0",
          min: 0,
        });

        const operationType = (await select({
          message: prefix + `Operation type`,
          choices: Object.keys(operationTypes).map((operationType) => ({
            name: operationType,
            value: operationType,
          })),
        })) as keyof typeof operationTypes;

        txs.push({ to, data, value, operation: operationTypes[operationType] });

        break;

      case TransactionType.transferFunds:
        let decimals!: number;
        const token = await input({
          message: prefix + `Token address`,
          validate: trial(async (value) => {
            if (!isAddress(value)) return "Invalid address";

            const erc20 = new Contract(
              value,
              ["function decimals() view returns (uint8)"],
              getDefaultProvider(process.env.FOUNDRY_ETH_RPC_URL!)
            );
            decimals = await erc20.decimals();

            return true;
          }, "Invalid ERC20 address"),
        });

        to = await address({ message: prefix + `Recipient address` });
        const amount = parseUnits(
          await input({
            message: prefix + `Amount`,
            validate: trial((value) => !!parseUnits(value, decimals), "Invalid amount"),
          }),
          decimals
        );

        txs.push(encodeSingle({ id: "", type: txType, to, token, amount: amount.toString(), decimals }));

        break;

      case TransactionType.transferCollectible:
        const collectible = await address({
          message: prefix + `Collectible address`,
        });

        const from = await address({ message: prefix + `From address`, default: process.env.SAFE });
        to = await address({ message: prefix + `Recipient address` });

        const tokenId = await input({
          message: prefix + `Token ID`,
          validate: trial((value) => !!toBigInt(value), "Invalid token ID"),
        });

        txs.push(encodeSingle({ id: "", type: txType, to, address: collectible, from, tokenId }));

        break;

      case TransactionType.raw:
        to = await address({ message: prefix + `Target address` });
        data = await input({
          message: prefix + `Calldata`,
          validate: trial((value) => isHexString(value), "Invalid calldata"),
        });

        value = await number({
          message: prefix + `Value (ETH)`,
          default: "0",
          min: 0,
        });

        txs.push(encodeSingle({ id: "", type: txType, to, data, value }));

        break;

      default:
        throw Error(`Unknown transaction type: "${txType}"`);
    }
  }

  const tx = txs.length > 1 ? encodeMulti(txs) : txs[0];

  writeFileSync(
    path.join("data", "tx.json"),
    JSON.stringify(
      {
        ...tx,
        safeTxGas: 0,
        baseGas: 0,
        gasPrice: 0,
        gasToken,
        refundReceiver: "0x0000000000000000000000000000000000000000",
      },
      undefined,
      4
    )
  );
})();
