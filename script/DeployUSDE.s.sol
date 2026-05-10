// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {USDE} from "../src/USDE.sol";

/// @notice Deploys {USDE}. See `.env.example` and `docs/DEPLOYMENT.md`.
contract DeployUSDE is Script {
    /// @dev Recommended mainnet minimum: 2 days (172800). Tests often use `0`.
    uint48 internal constant DEFAULT_ADMIN_DELAY_MAINNET = 172800;

    function run() external returns (USDE token) {
        string memory name_ = vm.envOr("TOKEN_NAME", string("USDE"));
        string memory symbol_ = vm.envOr("TOKEN_SYMBOL", string("USDE"));
        address admin = vm.envOr("TOKEN_ADMIN", address(0));
        uint256 maxSupply = vm.envOr("USDE_MAX_SUPPLY", uint256(0));
        uint48 adminDelay = uint48(vm.envOr("USDE_ADMIN_TRANSFER_DELAY", uint256(DEFAULT_ADMIN_DELAY_MAINNET)));

        uint256 pk = vm.envUint("PRIVATE_KEY");
        if (admin == address(0)) {
            admin = vm.addr(pk);
            console2.log("TOKEN_ADMIN not set; using deployer:", admin);
        }

        vm.startBroadcast(pk);
        token = new USDE(name_, symbol_, admin, maxSupply, adminDelay);
        vm.stopBroadcast();

        console2.log("USDE:", address(token));
        console2.log("name:", token.name());
        console2.log("symbol:", token.symbol());
        console2.log("decimals:", uint256(token.decimals()));
        console2.log("maxSupply (0=uncapped):", token.maxSupply());
        console2.log("defaultAdminDelay (seconds):", uint256(token.defaultAdminDelay()));
        console2.log("admin:", admin);
    }
}
