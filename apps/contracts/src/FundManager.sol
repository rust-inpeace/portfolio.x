//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IFundManager} from "@source/interface/IFundManager.sol";
import {IRegistryTrader} from "@source/interface/IRegistryTrader.sol";
import {StructTypes} from "@source/library/StructTypes.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20MetaData} from "@source/interface/IERC20MetaData.sol";

contract FundManager is ReentrancyGuard, Ownable, IFundManager {
    using SafeERC20 for IERC20;

    error FUND_MANAGER___USER_DEPOSIT_AMOUNT_ZERO();
    error FUND_MANAGER___INVALID_TRADER();
    error FUND_MANAGER___TRADER_ALREADY_REGISTERED();
    error FUND_MANAGER___TRADER_ALREADY_VERIFIED();
    error FUND_MANAGER___ZERO_ADDRESS();

    event FUND_MANAGER___TRADER_ASSIGN(address indexed trader, address indexed user);
    event FUND_MANAGER___USER_TOKEN_DEPOSIT(address indexed account, address indexed token, uint256 amount);

    address private registryTraderContract;
    mapping(address => mapping(address => uint256)) public userDeposit;
    mapping(address => uint256) public userFundsLockTimer;
    mapping(address => StructTypes.TraderStats) public registerTrader;

    /// @notice supported token user can deposit these token only
    address constant ETHH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 constant ETH_DECIMALS = 18;

    constructor(address _registryTraderContract) Ownable(msg.sender) {
        registryTraderContract = _registryTraderContract;
    }

    modifier onlyRegistryCall() {
        require(msg.sender == registryTraderContract);
        _;
    }

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
        emit FUND_MANAGER___USER_TOKEN_DEPOSIT(msg.sender, _token, _amount);
    }

    /// @notice Allow user to assign a trader to manage their funds.
    /// @dev The user must have deposited funds before assigning a trader.
    /// @param _trader The address of the trader to assign.
    /// @dev The trader must be registered in the system.
    function assignExpertTrader(address _trader) external {
        if (userDeposit[msg.sender][ETHH_ADDRESS] == 0 && userDeposit[msg.sender][USDC_ADDRESS] == 0
            && userDeposit[msg.sender][USDT_ADDRESS] == 0) revert FUND_MANAGER___USER_DEPOSIT_AMOUNT_ZERO();
        if (registerTrader[_trader].registered == false) revert FUND_MANAGER___INVALID_TRADER();
        registerTrader[_trader].handlingUsers.push(msg.sender);
        emit FUND_MANAGER___TRADER_ASSIGN(_trader, msg.sender);
    }

    /// @notice this function register trader in the system
    /// @dev this function only callable by registry trader contract
    /// @param _trader The address of the trader to register.
    /// @param _traderDeposit The deposit amount for the trader.
    /// @param _traderUri The URI for the trader's information.
    /// @return bool indicating success or failure of the operation.
    function bindTrader(address _trader, uint256 _traderDeposit, string memory _traderUri)
        external
        onlyRegistryCall
        returns (bool)
    {
        if (_trader == address(0)) revert FUND_MANAGER___ZERO_ADDRESS();
        if (registerTrader[_trader].registered) revert FUND_MANAGER___TRADER_ALREADY_REGISTERED();
        registerTrader[_trader] = StructTypes.TraderStats(_trader, true, _traderUri, _traderDeposit, false, false, new address[](0));
        return true;
    }

    function verification(address _trader, bool _status) external onlyRegistryCall returns (bool) {
        if (!registerTrader[_trader].registered) revert FUND_MANAGER___INVALID_TRADER();
        if (registerTrader[_trader].verified) revert FUND_MANAGER___TRADER_ALREADY_VERIFIED();
        registerTrader[_trader].verified = _status;
        return true;
    }

    function updateRegistryTraderContract(address _registryTraderContract) external onlyOwner {
        registryTraderContract = _registryTraderContract;
    }

    function getRegisteredTraderData(address _trader) public view returns (StructTypes.TraderStats memory) {
        return registerTrader[_trader];
    }

    function getUSDValue(uint256 _amount, address _token) public view returns (uint256) {
        AggregatorV3Interface chainLinkPriceFeed = AggregatorV3Interface(_token);
        (, int256 price, , , ) = chainLinkPriceFeed.latestRoundData();
        uint256 chainLinkDecimals = chainLinkPriceFeed.decimals();
        uint256 usdAmount = (_amount * uint256(price)) / (10**chainLinkDecimals);
        return usdAmount;
    }

    // note: trading used user deposit token like eth, usdc, usdc or portfolio token profit and fee calculate on only used token

    //     function calculatePartialWithdrawalFee(address _user, uint256 _amountToWithdraw, address _token) public view returns (uint256 fee, uint256 withdrawalAmount) {
    //     uint256 currentValueOfToken = getCurrentTokenValue(_user, _token);
    //     uint256 initialDepositValueOfToken = getInitialDepositValue(_user, _token);
    //     uint256 tokenProfit = currentValueOfToken - initialDepositValueOfToken; // profit on this token

    //     // If there is profit, calculate the fee
    //     if (tokenProfit > 0) {
    //         uint256 portfolioValue = getUserPortfolioValue(_user);
    //         uint256 portfolioProfit = portfolioValue - getInitialDepositValue(_user);

    //         // Calculate proportional profit for this token
    //         uint256 tokenProfitPercentage = tokenProfit * 100 / portfolioProfit;

    //         // Fee on the proportional profit
    //         uint256 totalProfitFee = tokenProfitPercentage * portfolioProfit / 100; // fee on the profit
    //         fee = totalProfitFee * _amountToWithdraw / currentValueOfToken;

    //         // Remaining withdrawal amount after fee
    //         withdrawalAmount = _amountToWithdraw - fee;
    //     } else {
    //         // No profit, no fee
    //         fee = 0;
    //         withdrawalAmount = _amountToWithdraw;
    //     }

    //     return (fee, withdrawalAmount);
    // }
}
