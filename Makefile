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

sign\:%: hash
	OUTPUT=$$(cast wallet sign --$* $$(cat data/hashData.txt)) && if [[ "$$OUTPUT" =~ "^0x" ]]; then $$OUTPUT >> data/signatures.txt; fi

simulate\:%:
	forge script script/ExecTransaction.s.sol --$*

exec\:%:
	forge script script/ExecTransaction.s.sol --$* --broadcast

clean:
	mkdir -p data
	cp data/template.json data/tx.json
	> data/hashData.txt
	> data/signatures.txt


.PHONY: contracts test coverage hash sign simulate exec clean
