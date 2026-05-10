# Mainnet launch checklist (USDE)

This project is engineered to **mainnet-oriented standards**: delayed default-admin transfer (OpenZeppelin `AccessControlDefaultAdminRules`), `nonReentrant` on sensitive entrypoints, monitoring events, fuzz tests, and explicit documentation of trust assumptions.

**You still must complete the items below before accepting user funds.** Listing this on a resume is credible when you can show you understand and executed (or scoped) each line.

## 1. Independent security review

- [ ] Engage a reputable audit firm; scope includes `USDE.sol`, deployment scripts, and any proxy you add later.
- [ ] Remediate findings; tag a release commit and preserve audit report in your portfolio (with permission).

## 2. Legal and compliance

- [ ] Jurisdiction-specific licensing (e.g. money transmission, e-money, securities).
- [ ] Terms of use, privacy, and redemption policy aligned with how you market USDE.
- This repository does not provide legal advice.

## 3. Key management and governance

- [ ] `TOKEN_ADMIN` / default admin is a **multisig** (e.g. hardware-backed Gnosis Safe), not an EOA.
- [ ] **Split roles** across multisigs or processes where possible: minter, pauser, blacklist admin, rescuer.
- [ ] Document signers, quorum, and key ceremony; use `USDE_ADMIN_TRANSFER_DELAY` ≥ **48 hours** on mainnet (deploy script default: 172800 seconds).

## 4. Deployment parameters

- [ ] `USDE_MAX_SUPPLY` aligned with treasury and regulatory limits (immutable after deploy).
- [ ] `TOKEN_NAME` matches EIP-712 permit domain expectations for wallets.
- [ ] Verify contract on block explorers; publish verified source or standard-json.

## 5. Operations

- [ ] Monitoring and alerting: `USDEMinted`, `Paused`, `AccountFrozenChange`, `RoleGranted`, `RoleRevoked`, large transfers.
- [ ] Incident runbooks: pause, freeze, communication, and legal escalation.
- [ ] Reserve reporting / attestations if you claim USD backing (off-chain).

## 6. Ongoing

- [ ] Bug bounty (optional but strong signal for production intent).
- [ ] Process for dependency updates (`lib/openzeppelin-contracts`) with re-testing.

## Resume framing (honest)

Strong phrasing: *“Designed and implemented USDE, an ERC-20 stablecoin-style token with OZ AccessControlDefaultAdminRules, reentrancy guards, supply cap, pause/freeze, EIP-2612 permit, and Foundry test coverage including fuzzing; documented mainnet launch and trust model.”*

Avoid claiming “audited” or “production-deployed” unless true.
