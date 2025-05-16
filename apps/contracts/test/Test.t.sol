//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundManager} from "@source/FundManager.sol";
import {RegistryTrader} from "@source/RegistryTrader.sol";
import {DeployScript} from "script/DeployScript.s.sol";
import {console} from "forge-std/console.sol";
import {StructTypes} from "@source/library/StructTypes.sol";

contract TestScript is Test {
    FundManager public fundManager;
    RegistryTrader public registryTrader;

    address public owner;
    uint256 private ownerPrivateKey;

    address public trader;
    uint256 private traderPrivateKey;

    function setUp() public {
        DeployScript deploy = new DeployScript();
        (fundManager, registryTrader, owner, ownerPrivateKey) = deploy.run();
        (trader, traderPrivateKey) = makeAddrAndKey("trader");
    }

    function testContracts() public view {
        console.log("FundManager Address: ", address(fundManager)); 
        console.log("RegistryTrader Address: ", address(registryTrader));
        console.log("Owner of FundManager: ", fundManager.owner());
        console.log("Owner of RegistryTrader: ", registryTrader.owner());
        console.log("Owner address: ", owner);
        console.log("Trader address: ", trader);
    }


    function testTraderRegistration() public {
        vm.deal(trader, 20 ether);
        console.log("Trader Address Balancer: ", trader.balance);
        vm.prank(trader);
        string memory traderInfoUri = "https://example.com/trader";
        uint256 traderDeposit = 19 ether;
        registryTrader.registerTrader{value: traderDeposit}(traderInfoUri);
        StructTypes.TraderStats memory types = fundManager.getRegisteredTraderData(trader);
        console.log("Trader Address: ", types.registered);
        console.log("Registry Address Balancer: ", address(registryTrader).balance);
        console.log("Trader Address Balancer: ", types.depositBalance);

        bytes32 digest = registryTrader.getMessageHash(trader, true);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.prank(trader);
        registryTrader.verifyTraderProfile(trader, true, v, r, s);
        StructTypes.TraderStats memory types_2 = fundManager.getRegisteredTraderData(trader);
        console.log("Trader verified: ", types_2.verified);
    }
}