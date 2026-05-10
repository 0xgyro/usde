# Security — USDE

## Trust model

The contract is **permissioned**: privileged roles can mint, pause, freeze, and rescue foreign tokens. The **USD peg is not enforced on-chain**.

## Default admin

`AccessControlDefaultAdminRules` prevents casual reassignment of `DEFAULT_ADMIN_ROLE`: two-step process + delay. This reduces “fat finger” admin grants but **does not** remove trust in the admin holder.

Configure a **non-zero** `adminTransferDelay` on mainnet (deploy script defaults to 48h).

## Reentrancy

`mint` and `rescueERC20` are `nonReentrant`. Standard ERC-20 transfers do not reenter USDE under normal ERC-20 behavior.

## Pre-mainnet

External audit, multisig, role separation, monitoring — see [MAINNET_LAUNCH.md](./MAINNET_LAUNCH.md).

## Dependencies

Pinned OpenZeppelin under `lib/openzeppelin-contracts`. Run `slither .` (optional) with `slither.config.json`.
