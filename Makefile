-include .env
.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

NETWORK ?= ethereum-mainnet


install: clean
	yarn
	foundryup
	forge install

hash:
	forge script script/HashData.s.sol

sign\:%: hash
	OUTPUT=$$(cast wallet sign --$* $$(cat data/hashData.txt)) && echo "$$OUTPUT" >> data/signatures.txt
	@echo "\033[0;32mTx signature successfully appended to data/signatures.txt"

simulate\:%:
	forge script script/ExecTransaction.s.sol --$*

exec\:%:
	forge script script/ExecTransaction.s.sol --$* --broadcast

clean:
	mkdir -p data
	> data/hashData.txt
	> data/signatures.txt


.PHONY: contracts test coverage
