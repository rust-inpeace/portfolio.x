//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library StructTypes {
    struct TraderStats {
        address trader;
        bool registered;
        string traderInfoUri;
        uint256 depositBalance;
        bool verified;
        bool canWithdraw;
        address[] handlingUsers;
    }
}