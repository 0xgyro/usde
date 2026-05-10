// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title USDE — USD for Ether
 * @notice ERC-20 unit intended to represent **one U.S. dollar** per 10**6 smallest units (6 decimals), matching
 *         the UX of USDC/USDT on Ethereum. The **peg is not enforced by this contract**: redeemability,
 *         reserves, and attestations live in your banking, custody, and legal layer.
 *
 * **Mainnet-oriented controls:**
 * - {AccessControlDefaultAdminRules} — single default admin, **two-step delayed transfer** (no `grantRole` on default admin).
 * - `nonReentrant` on {mint} and {rescueERC20}.
 * - {USDEMinted} for operational monitoring.
 * - Role-gated mint, pause, freeze, foreign-token rescue; optional immutable supply cap; EIP-2612 permit.
 *
 * @dev Before deploying with user funds: external audit, legal review, multisig admin, and operational readiness
 *      (see `docs/MAINNET_LAUNCH.md`). This code is a portfolio-grade baseline, not a substitute for those steps.
 */
contract USDE is ERC20Permit, ERC20Pausable, ERC20Burnable, AccessControlDefaultAdminRules, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLACKLIST_ADMIN_ROLE = keccak256("BLACKLIST_ADMIN_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");

    /// @notice Upper bound on `totalSupply()` after any mint. If `0`, minting is uncapped on-chain.
    uint256 public immutable maxSupply;

    mapping(address account => bool) private _frozen;

    error AccountFrozen(address account);
    error USDESupplyCapExceeded(uint256 totalSupplyAfterMint, uint256 cap);
    error USDECannotRescueSelf();

    event AccountFrozenChange(address indexed account, bool frozen);
    /// @notice Emitted after a successful mint (indexers: tie to `Transfer` from zero address).
    event USDEMinted(address indexed minter, address indexed to, uint256 amount);

    /**
     * @param name_ ERC-20 name and EIP-712 permit domain name.
     * @param symbol_ Ticker, typically `USDE`.
     * @param admin Initial default admin and recipient of operational roles; use a multisig on mainnet.
     * @param maxSupply_ Global mint cap; `0` means no on-chain cap (immutable).
     * @param adminTransferDelay_ Seconds before a pending default admin can accept (use 48h+ on mainnet; `0` only for testing).
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address admin,
        uint256 maxSupply_,
        uint48 adminTransferDelay_
    ) ERC20(name_, symbol_) ERC20Permit(name_) AccessControlDefaultAdminRules(adminTransferDelay_, admin) {
        maxSupply = maxSupply_;
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(BLACKLIST_ADMIN_ROLE, admin);
        _grantRole(RESCUER_ROLE, admin);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Mint `amount` to `to`. Emits {USDEMinted} then ERC-20 `Transfer` from zero address.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) nonReentrant {
        if (maxSupply != 0) {
            uint256 supply = totalSupply();
            unchecked {
                if (supply + amount > maxSupply) {
                    revert USDESupplyCapExceeded(supply + amount, maxSupply);
                }
            }
        }
        emit USDEMinted(_msgSender(), to, amount);
        _mint(to, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function freeze(address account) external onlyRole(BLACKLIST_ADMIN_ROLE) {
        _frozen[account] = true;
        emit AccountFrozenChange(account, true);
    }

    function unfreeze(address account) external onlyRole(BLACKLIST_ADMIN_ROLE) {
        _frozen[account] = false;
        emit AccountFrozenChange(account, false);
    }

    function isFrozen(address account) external view returns (bool) {
        return _frozen[account];
    }

    function rescueERC20(IERC20 foreignToken, address to, uint256 amount) external onlyRole(RESCUER_ROLE) nonReentrant {
        if (address(foreignToken) == address(this)) revert USDECannotRescueSelf();
        foreignToken.safeTransfer(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20Pausable, ERC20) {
        if (from != address(0) && _frozen[from]) revert AccountFrozen(from);
        if (to != address(0) && _frozen[to]) revert AccountFrozen(to);
        super._update(from, to, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
