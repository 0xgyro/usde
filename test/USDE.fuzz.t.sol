// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {USDE} from "../src/USDE.sol";

contract USDEFuzzTest is Test {
    USDE internal token;
    address internal admin = address(0xAD01);
    address internal minter = address(0xAD02);
    address internal alice = address(0xA1);

    function setUp() public {
        vm.startPrank(admin);
        token = new USDE("USDE Test", "USDE", admin, 0, 0);
        token.grantRole(token.MINTER_ROLE(), minter);
        vm.stopPrank();
    }

    function testFuzz_mint_respects_cap(uint256 firstMint, uint256 secondMint) public {
        uint256 cap = 10_000_000;
        vm.startPrank(admin);
        USDE capped = new USDE("C", "USDE", admin, cap, 0);
        capped.grantRole(capped.MINTER_ROLE(), minter);
        vm.stopPrank();

        firstMint = bound(firstMint, 0, cap);
        // Keep both mints within cap so `firstMint + secondMint` never overflows uint256.
        secondMint = bound(secondMint, 0, cap);

        vm.prank(minter);
        capped.mint(alice, firstMint);

        uint256 remaining = cap - firstMint;

        vm.prank(minter);
        if (secondMint > remaining) {
            uint256 supplyAfter;
            unchecked {
                supplyAfter = firstMint + secondMint;
            }
            vm.expectRevert(abi.encodeWithSelector(USDE.USDESupplyCapExceeded.selector, supplyAfter, cap));
            capped.mint(alice, secondMint);
        } else {
            capped.mint(alice, secondMint);
            unchecked {
                assertEq(capped.totalSupply(), firstMint + secondMint);
            }
        }
    }

    function testFuzz_transfer_preserves_totalSupply(uint256 mintAmt, uint256 xferAmt) public {
        mintAmt = bound(mintAmt, 1, 1e15);
        xferAmt = bound(xferAmt, 0, mintAmt);

        address bob = address(0xB0);
        vm.prank(minter);
        token.mint(alice, mintAmt);

        uint256 tsBefore = token.totalSupply();
        vm.prank(alice);
        assertTrue(token.transfer(bob, xferAmt));
        assertEq(token.totalSupply(), tsBefore);
        assertEq(token.balanceOf(alice) + token.balanceOf(bob), tsBefore);
    }
}
