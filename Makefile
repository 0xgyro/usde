.PHONY: build test fmt slither

build:
	forge build

test:
	forge test -vvv

fmt:
	forge fmt

# Requires: pip install slither-analyzer && solc-select
slither:
	slither .
