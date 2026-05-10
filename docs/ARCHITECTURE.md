# Architecture — USDE

## Overview

`USDE` combines OpenZeppelin **ERC-20**, **ERC20Pausable**, **ERC20Burnable**, **ERC20Permit**, **`AccessControlDefaultAdminRules`**, and **ReentrancyGuard**.

## Default admin safety

`AccessControlDefaultAdminRules` (OZ v5) enforces:

- Only one `DEFAULT_ADMIN_ROLE` holder at a time (until renounced per OZ rules).
- **No `grantRole(DEFAULT_ADMIN_ROLE, …)`** — transfers use `beginDefaultAdminTransfer` → wait `defaultAdminDelay` → `acceptDefaultAdminTransfer`.
- Configurable delay at deploy (`adminTransferDelay_`); deploy script defaults to **48 hours** on mainnet.

Operational roles (`MINTER_ROLE`, etc.) are still granted with `grantRole` by the default admin.

## Roles

| Role | Function |
|------|----------|
| `DEFAULT_ADMIN_ROLE` | Grant/revoke non-default roles; schedule admin transfer |
| `MINTER_ROLE` | `mint` |
| `PAUSER_ROLE` | `pause` / `unpause` |
| `BLACKLIST_ADMIN_ROLE` | `freeze` / `unfreeze` |
| `RESCUER_ROLE` | `rescueERC20` (not USDE itself) |

## Reentrancy

`mint` and `rescueERC20` use `nonReentrant`.

## Events

- `USDEMinted(minter, to, amount)` — after policy checks, before `_mint`
- `AccountFrozenChange`, `Paused` / `Unpaused`, `RoleGranted` / `RoleRevoked`, OZ default-admin transfer events

## Supply cap

`maxSupply` is immutable; `0` means uncapped on-chain.

## Files

- `src/USDE.sol` — implementation
- `test/USDE.t.sol`, `test/USDE.fuzz.t.sol` — tests
