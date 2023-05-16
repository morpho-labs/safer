-include .env
.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

NETWORK ?= ethereum-mainnet


install: clean
	foundryup
	forge install

tx:
	npx create-safe-tx

hash:
	forge script script/HashData.s.sol

sign\:%:
	cast wallet sign --$* $$(cat data/hashData.txt) >> data/signatures.txt

simulate\:%:
	forge script script/ExecTransaction.s.sol --$*

exec\:%:
	forge script script/ExecTransaction.s.sol --$* --broadcast

clean:
	cp data/template.json data/tx.json
	> data/hashData.txt
	> data/signatures.txt


.PHONY: contracts test coverage
