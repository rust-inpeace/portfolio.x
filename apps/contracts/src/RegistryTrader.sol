//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRegistryTrader} from "@source/interface/IRegistryTrader.sol";
import {IFundManager} from "@source/interface/IFundManager.sol";

contract RegistryTrader is IRegistryTrader {
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

    IFundManager immutable ifundManager;

    constructor(address _ifundManager) {
        ifundManager = IFundManager(_ifundManager);
    }

    /// @inheritdoc IRegistryTrader
    function registerTrader(address _trader, string memory _traderInfoUri) external payable {
        require(msg.value >= traderDepositAmount);
        traderDeposit[_trader] = TraderStats(
            _trader,
            _traderInfoUri,
            msg.value,
            false,
            false,
            new address[](0)
        );
    }

    /// @inheritdoc IRegistryTrader
    function unregisterTrader(address _trader) external {
        require(traderDeposit[_trader].canWithdraw);
        (bool success, ) = _trader.call{
            value: traderDeposit[_trader].depositBalance
        }("");
        require(success);
    }
}
