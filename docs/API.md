# Public API — USDE (integrators)

## Constructor

`constructor(string name_, string symbol_, address admin, uint256 maxSupply_, uint48 adminTransferDelay_)`

## ERC-20

| Function | Notes |
|----------|--------|
| `name` / `symbol` | Immutable |
| `decimals()` | Always `6` |
| `totalSupply` / `balanceOf` / `allowance` | Standard |
| `transfer` / `transferFrom` / `approve` | OpenZeppelin revert-on-fail |
| `burn` / `burnFrom` | `ERC20Burnable`; respects pause + freeze |

## Mint

| Function | Notes |
|----------|--------|
| `mint(address to, uint256 amount)` | `MINTER_ROLE`, `nonReentrant`; emits `USDEMinted` then `Transfer` from `0` |

## Pause

| Function | Notes |
|----------|--------|
| `pause()` / `unpause()` | `PAUSER_ROLE` |

## Freeze

| Function | Notes |
|----------|--------|
| `freeze` / `unfreeze` | `BLACKLIST_ADMIN_ROLE` |
| `isFrozen` | View |

## Permit (EIP-2612)

`permit`, `nonces`, `DOMAIN_SEPARATOR` — domain **name** matches `name()`.

## Rescue

`rescueERC20(IERC20 foreignToken, address to, uint256 amount)` — `RESCUER_ROLE`, `nonReentrant`; reverts if `foreignToken == address(this)`.

## Default admin (OpenZeppelin)

| Function | Notes |
|----------|--------|
| `defaultAdmin()` | Current admin |
| `defaultAdminDelay()` | Delay for acceptance |
| `pendingDefaultAdmin()` | Pending handover + schedule |
| `beginDefaultAdminTransfer(address)` | Start 2-step transfer |
| `acceptDefaultAdminTransfer()` | New admin accepts after delay |
| `cancelDefaultAdminTransfer()` | Cancel pending |
| `changeDefaultAdminDelay` / `rollbackDefaultAdminDelay` | Delay governance |

`grantRole` / `revokeRole` **revert** for `DEFAULT_ADMIN_ROLE` — use the flow above.

## Other access control

`hasRole`, `getRoleAdmin`, `grantRole`, `revokeRole`, `renounceRole`, `supportsInterface` — see OpenZeppelin `AccessControl` + `IAccessControlDefaultAdminRules`.

## Constants

`MINTER_ROLE`, `PAUSER_ROLE`, `BLACKLIST_ADMIN_ROLE`, `RESCUER_ROLE`, `DEFAULT_ADMIN_ROLE`.

## Views

`maxSupply` — immutable cap (`0` uncapped).

## Errors

| Error | When |
|-------|------|
| `AccountFrozen` | Frozen `from`/`to` |
| `USDESupplyCapExceeded` | Mint over cap |
| `USDECannotRescueSelf` | Rescue USDE |
| `ReentrancyGuardReentrantCall` | Reentrant call |
| OZ `AccessControl*` | Roles / admin delay rules |
| OZ ERC-20 / EIP-2612 | Standard |
