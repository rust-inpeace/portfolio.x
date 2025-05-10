//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {IFundManager} from "@source/interface/IFundManager.sol";

contract FundManager is ReentrancyGuard, Ownable, IFundManager {
    using SafeERC20 for IERC20;

    error FundManager__TokenIsNotAllowed();

    mapping(address => mapping(address => uint256)) public userDeposit;
    mapping(address => uint256) public userFundsLockTimer;
    mapping(address => bool) public availableTraders;
    // mapping(address => address) 

    /// @notice supported token user can deposit these token only
    address constant ETHH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice Emitted When user deposit token
    event FundManager__UserTokenDeposit(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    constructor() Ownable(msg.sender) {}

    /// @notice Allows a user to deposit either ETH, USDC, or USDT into the contract.
    /// @dev For ETH deposits, use the predefined ETHH_ADDRESS as the _token parameter.
    /// @param _token The address of the token to deposit (ETHH_ADDRESS for ETH, or token address for USDC/USDT).
    /// @param _amount The amount of ETH or ERC20 tokens (USDC/USDT) to deposit.
    function deposit(address _token, uint256 _amount) external payable nonReentrant {
        require(_amount > 0);
        if (_token == ETHH_ADDRESS && msg.value == _amount) {
            userDeposit[msg.sender][ETHH_ADDRESS] += msg.value;
        } else {
            require(msg.value == 0);
            require(_token == USDC_ADDRESS || _token == USDT_ADDRESS);
            require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount);
            userDeposit[msg.sender][_token] += _amount;
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
        emit FundManager__UserTokenDeposit(msg.sender, _token, _amount);
    }

    function assignExpertTrader() external {}

    function joinTrader(address _trader) external {

    }

}
