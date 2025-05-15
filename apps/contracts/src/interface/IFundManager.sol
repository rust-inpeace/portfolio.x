//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StructTypes} from "@source/library/StructTypes.sol";

interface IFundManager {
    function bindTrader(address _trader, uint256 _traderDeposit, string memory _traderUri) external returns (bool);
    function verification(address _trader, bool _status) external returns (bool);
    function getRegisteredTraderData(address _trader) external view returns (StructTypes.TraderStats memory);
}
