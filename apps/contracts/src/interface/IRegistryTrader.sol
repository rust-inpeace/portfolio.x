//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRegistryTrader {
    function registerTrader(
        string memory _traderInfoUri
    ) external payable;

    function unregisterTrader(address _trader) external;

    function connectRegistryTrader(address _fundmanager) external;
}