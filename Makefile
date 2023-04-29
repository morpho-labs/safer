-include .env
.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

NETWORK ?= ethereum-mainnet


install:
	foundryup
	forge install

hash:
	forge script script/HashData.s.sol --rpc-url rpc

sign\:%:
	cast wallet sign --$* $$(cat signatures/hashData.txt)

exec\:%:
	forge script script/ExecTransaction.s.sol --$* --broadcast --rpc-url rpc >> signatures/signatures.txt

clean:
	> signatures/hashData.txt
	> signatures/signatures.txt


.PHONY: contracts test coverage
