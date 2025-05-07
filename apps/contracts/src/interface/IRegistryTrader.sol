//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRegistryTrader {
    function registerTrader(
        address _trader,
        string memory _traderInfoUri
    ) external payable;

    function unregisterTrader(address _trader) external;
}
