# Peg, reserves, and “USD for Ether”

## What USDE means on-chain

**USDE** is named **USD for Ether**: each **1e6** smallest unit is intended to represent **one U.S. dollar** of account value (6 decimals, same convention as USDC on Ethereum).

The smart contract **does not**:

- Hold USD in a bank account
- Prove collateral or issue attestations
- Force the market price to \$1.00
- Replace legal, compliance, or treasury operations

The **peg is an operational and economic commitment** you maintain off-chain—mirroring how USDC/USDT work: the token is ERC-20 accounting; reserves and redemption are organizational.

## How issuers typically preserve the peg

1. **Mint discipline** — Mint only when USD (or policy-approved assets) is received or credit is extended under clear rules.
2. **Redemption** — Burn USDE when USD is paid out or obligations are settled, shrinking supply alongside liabilities.
3. **Reserves** — Hold liquid, high-quality assets segregated from operating cash; publish balance sheets or third-party attestations on a schedule you define.
4. **Risk limits** — Use `maxSupply` (on-chain cap) as a hard ceiling aligned with your balance sheet.
5. **Governance** — Separate `MINTER_ROLE`, `PAUSER_ROLE`, `BLACKLIST_ADMIN_ROLE`, and `RESCUER_ROLE` across people, multisigs, and timelocks.

## Price on DEXs

Secondary-market trading can deviate from \$1.00. Arbitrage and redemption windows close gaps only if your **off-chain** process reliably converts between USDE and USD at par.

## Regulatory note

Issuing something marketed as dollar-pegged may trigger money-transmitter, e-money, or securities rules depending on jurisdiction. This documentation is **not legal advice**.
