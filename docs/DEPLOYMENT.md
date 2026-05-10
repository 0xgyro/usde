# Deployment — USDE

## Environment variables

| Variable | Default (script) | Notes |
|----------|------------------|--------|
| `PRIVATE_KEY` | (required) | Broadcast signer |
| `TOKEN_NAME` | `USDE` | ERC-20 + EIP-712 domain name |
| `TOKEN_SYMBOL` | `USDE` | |
| `TOKEN_ADMIN` | deployer | Use mainnet **multisig** address |
| `USDE_MAX_SUPPLY` | `0` | Base units (6 decimals); `0` = uncapped |
| `USDE_ADMIN_TRANSFER_DELAY` | `172800` | **48 hours**; set `0` only for local/testing |

## Commands

```bash
forge script script/DeployUSDE.s.sol:DeployUSDE --rpc-url "$RPC_URL" -vvvv
forge script script/DeployUSDE.s.sol:DeployUSDE --rpc-url "$RPC_URL" --broadcast --verify
```

## After deploy

Complete [MAINNET_LAUNCH.md](./MAINNET_LAUNCH.md) before user funds.

## Acceptance timing

OpenZeppelin requires `block.timestamp > acceptSchedule` (strict) for `acceptDefaultAdminTransfer`. Plan monitoring around scheduled handover times.
