//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRegistryTrader} from "@source/interface/IRegistryTrader.sol";
import {IFundManager} from "@source/interface/IFundManager.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol"
;
contract RegistryTrader is Ownable ,IRegistryTrader {
    uint256 public traderDepositAmount = 19 ether;

    struct TraderStats {
        address trader;
        string traderInfoUri;
        uint256 depositBalance;
        bool varified;
        bool canWithdraw;
        address[] handlingUsers;
    }

    mapping(address => TraderStats) public traderDeposit;

    IFundManager private ifundManager;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IRegistryTrader
    function registerTrader(string memory _traderInfoUri) external payable {
        require(msg.value >= traderDepositAmount);
        traderDeposit[msg.sender] = TraderStats(
            msg.sender,
            _traderInfoUri,
            msg.value,
            false,
            false,
            new address[](0)
        );
        ifundManager.bindTrader(msg.sender);
    }

    /// @inheritdoc IRegistryTrader
    function unregisterTrader(address _trader) external {
        require(traderDeposit[_trader].canWithdraw);
        (bool success, ) = _trader.call{
            value: traderDeposit[_trader].depositBalance
        }("");
        require(success);
    }

    function connectRegistryTrader(address _fundmanager) external onlyOwner {
        ifundManager = IFundManager(_fundmanager);
    }
}
