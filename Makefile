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
	forge script script/ExecTransaction.s.sol --$* --broadcast --rpc-url rpc


.PHONY: contracts test coverage
