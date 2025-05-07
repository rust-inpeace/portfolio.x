//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract FundManager {
    mapping(address => mapping(address => uint256)) public userDeposit;

    function deposit(address _token, uint256 _amount) external payable {
        require(_amount > 0);
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value == _amount);
            userDeposit[msg.sender][_token] += msg.value;
        } else {
            require(msg.value == 0);
            userDeposit[msg.sender][_token] += _amount;
            require(
                IERC20(_token).transferFrom(msg.sender, address(this), _amount)
            );
        }
    }
}
