// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {USDE} from "../src/USDE.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

/// @dev Dummy token for rescue tests.
contract ForeignToken is ERC20 {
    constructor() ERC20("Foreign", "FGN") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract USDETest is Test {
    USDE internal token;

    address internal admin = address(0xAD01);
    address internal minter = address(0xAD02);
    address internal pauser = address(0xAD03);
    address internal blacklistAdmin = address(0xAD04);
    address internal rescuer = address(0xAD05);
    address internal alice = address(0xA1);
    address internal bob = address(0xB0);

    uint256 internal ownerPk = 0xBEEF;

    function setUp() public {
        vm.startPrank(admin);
        token = new USDE("USDE Test", "USDE", admin, 0, 0);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.PAUSER_ROLE(), pauser);
        token.grantRole(token.BLACKLIST_ADMIN_ROLE(), blacklistAdmin);
        token.grantRole(token.RESCUER_ROLE(), rescuer);
        vm.stopPrank();
    }

    function test_metadata() public view {
        assertEq(token.name(), "USDE Test");
        assertEq(token.symbol(), "USDE");
        assertEq(token.decimals(), 6);
        assertEq(token.maxSupply(), 0);
        assertEq(token.defaultAdmin(), admin);
        assertEq(token.defaultAdminDelay(), 0);
    }

    function test_mint_transfer_burn() public {
        uint256 amount = 1_000_000;

        vm.prank(minter);
        token.mint(alice, amount);
        assertEq(token.balanceOf(alice), amount);

        vm.prank(alice);
        assertTrue(token.transfer(bob, 400_000));
        assertEq(token.balanceOf(bob), 400_000);
        assertEq(token.balanceOf(alice), 600_000);

        vm.prank(alice);
        token.burn(100_000);
        assertEq(token.balanceOf(alice), 500_000);
    }

    function test_mint_emits_USDEMinted() public {
        vm.expectEmit(true, true, false, true);
        emit USDEMinted(minter, alice, 100);
        vm.prank(minter);
        token.mint(alice, 100);
    }

    event USDEMinted(address indexed minter, address indexed to, uint256 amount);

    function test_mint_reverts_without_role() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", address(this), token.MINTER_ROLE()
            )
        );
        token.mint(alice, 1);
    }

    function test_cannot_grant_default_admin_role() public {
        address rogue = address(0xBAD);
        bytes32 defaultAdminRole = token.DEFAULT_ADMIN_ROLE();
        vm.startPrank(admin);
        vm.expectRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        token.grantRole(defaultAdminRole, rogue);
        vm.stopPrank();
    }

    function test_supply_cap_blocks_mint() public {
        vm.startPrank(admin);
        USDE capped = new USDE("Capped", "USDE", admin, 500_000, 0);
        capped.grantRole(capped.MINTER_ROLE(), minter);
        vm.stopPrank();

        vm.prank(minter);
        capped.mint(alice, 400_000);

        vm.prank(minter);
        vm.expectRevert(abi.encodeWithSelector(USDE.USDESupplyCapExceeded.selector, 600_000, 500_000));
        capped.mint(alice, 200_000);
    }

    function test_supply_cap_allows_mint_to_cap() public {
        vm.startPrank(admin);
        USDE capped = new USDE("Capped", "USDE", admin, 500_000, 0);
        capped.grantRole(capped.MINTER_ROLE(), minter);
        vm.stopPrank();

        vm.prank(minter);
        capped.mint(alice, 500_000);
        assertEq(capped.totalSupply(), 500_000);
    }

    function test_pause_blocks_transfer() public {
        vm.prank(minter);
        token.mint(alice, 1_000_000);

        vm.prank(pauser);
        token.pause();

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1);

        vm.prank(pauser);
        token.unpause();

        vm.prank(alice);
        assertTrue(token.transfer(bob, 1));
        assertEq(token.balanceOf(bob), 1);
    }

    function test_freeze_blocks_transfer() public {
        vm.prank(minter);
        token.mint(alice, 1_000_000);

        vm.prank(blacklistAdmin);
        token.freeze(alice);

        assertTrue(token.isFrozen(alice));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(USDE.AccountFrozen.selector, alice));
        token.transfer(bob, 1);

        vm.prank(blacklistAdmin);
        token.unfreeze(alice);

        vm.prank(alice);
        assertTrue(token.transfer(bob, 1));
    }

    function test_freeze_blocks_incoming() public {
        vm.prank(minter);
        token.mint(alice, 1_000_000);

        vm.prank(blacklistAdmin);
        token.freeze(bob);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(USDE.AccountFrozen.selector, bob));
        token.transfer(bob, 1);
    }

    function test_constructor_zero_admin_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, address(0)
            )
        );
        new USDE("X", "Y", address(0), 0, 0);
    }

    function test_default_admin_two_step_after_delay() public {
        uint48 delay = 3600;
        address newAdmin = address(0xCAFE);

        vm.prank(admin);
        USDE t = new USDE("T", "USDE", admin, 0, delay);

        vm.prank(admin);
        t.beginDefaultAdminTransfer(newAdmin);

        (, uint48 schedule) = t.pendingDefaultAdmin();
        assertGt(schedule, 0);

        vm.prank(newAdmin);
        vm.expectRevert();
        t.acceptDefaultAdminTransfer();

        // OpenZeppelin: acceptance requires block.timestamp > acceptSchedule (strict).
        vm.warp(uint256(schedule) + 1);
        vm.prank(newAdmin);
        t.acceptDefaultAdminTransfer();

        assertEq(t.defaultAdmin(), newAdmin);
    }

    function test_permit_sets_allowance() public {
        address owner = vm.addr(ownerPk);
        address spender = bob;
        uint256 value = 500_000;
        uint256 deadline = block.timestamp + 1 days;

        vm.prank(minter);
        token.mint(owner, 1_000_000);

        bytes32 permitTypehash =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        bytes32 structHash = keccak256(abi.encode(permitTypehash, owner, spender, value, token.nonces(owner), deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
    }

    function test_burnFrom_respects_allowance() public {
        vm.prank(minter);
        token.mint(alice, 1_000_000);

        vm.prank(alice);
        token.approve(bob, 300_000);

        vm.prank(bob);
        token.burnFrom(alice, 200_000);
        assertEq(token.balanceOf(alice), 800_000);
    }

    function test_rescueERC20_moves_foreign_token() public {
        ForeignToken foreign = new ForeignToken();
        foreign.mint(address(token), 1_000);

        vm.prank(rescuer);
        token.rescueERC20(foreign, bob, 1_000);

        assertEq(foreign.balanceOf(bob), 1_000);
        assertEq(foreign.balanceOf(address(token)), 0);
    }

    function test_rescueERC20_reverts_for_self() public {
        vm.prank(minter);
        token.mint(address(token), 100);

        vm.prank(rescuer);
        vm.expectRevert(USDE.USDECannotRescueSelf.selector);
        token.rescueERC20(token, bob, 100);
    }
}
