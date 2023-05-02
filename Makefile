-include .env
.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

NETWORK ?= ethereum-mainnet


install: clean
	foundryup
	forge install

hash:
	forge script script/HashData.s.sol

sign\:%:
	cast wallet sign --$* $$(cat data/hashData.txt) >> data/signatures.txt

exec\:%:
	forge script script/ExecTransaction.s.sol --$* --broadcast

clean:
	cp data/template.json data/tx.json
	> data/hashData.txt
	> data/signatures.txt


.PHONY: contracts test coverage
