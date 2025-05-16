// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FundManager} from "@source/FundManager.sol";
import {RegistryTrader} from "@source/RegistryTrader.sol";

contract DeployScript is Script {
    FundManager public fundManager;
    RegistryTrader public registryTrader;

    function run() external returns (FundManager, RegistryTrader, address, uint256) {
        (address owner, uint256 ownerPrivateKey) = makeAddrAndKey("owner");
        vm.startBroadcast(ownerPrivateKey);
        registryTrader = new RegistryTrader();
        fundManager = new FundManager(address(registryTrader));
        registryTrader.connectRegistryTrader(address(fundManager));
        vm.stopBroadcast();
        return (fundManager, registryTrader, owner, ownerPrivateKey);
    }
}
