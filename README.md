# USDE — USD for Ether

Mainnet-oriented ERC-20: **1 USDE = 1e6 base units (6 decimals)**, intended to track **one U.S. dollar** of accounting (peg enforced **off-chain** — see [docs/PEG_AND_RESERVES.md](docs/PEG_AND_RESERVES.md)).

## Engineering highlights (portfolio / production track)

| Feature | Why it matters |
|---------|----------------|
| **OpenZeppelin `AccessControlDefaultAdminRules`** | Single default admin, **two-step delayed handover** — you cannot `grantRole(DEFAULT_ADMIN)` ad hoc. |
| **`nonReentrant`** on `mint` / `rescueERC20` | Reduces reentrancy risk on privileged entrypoints. |
| **`USDEMinted`** event | Clear operational signal for indexers / monitoring. |
| Mint cap, pause, freeze, permit, rescue | Same *control surface* family as USDC-style tokens. |
| **Foundry**: unit + **fuzz** tests | `forge test` includes supply-cap and transfer invariants under fuzz. |

**Before real users and real money:** external **audit**, **legal/compliance**, multisig admin, and the [docs/MAINNET_LAUNCH.md](docs/MAINNET_LAUNCH.md) checklist. This repo is suitable to show on a **resume** as a serious implementation — not as proof of an audited mainnet launch unless you complete those steps.

## Quick start

```bash
git submodule update --init --recursive
forge build
forge test -vvv
```

Static analysis (optional): [Slither](https://github.com/crytic/slither) — `slither .` (see `slither.config.json`).

## Docs

| Doc | Purpose |
|-----|---------|
| [docs/MAINNET_LAUNCH.md](docs/MAINNET_LAUNCH.md) | Pre-mainnet checklist + honest resume wording |
| [docs/PEG_AND_RESERVES.md](docs/PEG_AND_RESERVES.md) | USD peg / treasury practice |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Roles, inheritance, admin delay |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Env vars and `forge script` |
| [docs/SECURITY.md](docs/SECURITY.md) | Trust model |
| [docs/API.md](docs/API.md) | Integrator reference |

## Deploy

```bash
cp .env.example .env
# PRIVATE_KEY, optional USDE_MAX_SUPPLY, USDE_ADMIN_TRANSFER_DELAY (default 48h for mainnet script)

forge script script/DeployUSDE.s.sol:DeployUSDE \
  --rpc-url "$RPC_URL" \
  --broadcast
```

## Layout

```
src/USDE.sol
script/DeployUSDE.s.sol
test/USDE.t.sol          # unit / integration-style tests
test/USDE.fuzz.t.sol     # fuzz tests
```

## License

MIT — [LICENSE](LICENSE). OpenZeppelin: see `lib/openzeppelin-contracts`.
