//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRegistryTrader} from "@source/interface/IRegistryTrader.sol";
import {IFundManager} from "@source/interface/IFundManager.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {EIP712} from "@openzeppelin/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";

contract RegistryTrader is Ownable, IRegistryTrader, EIP712 {
    uint256 public traderDepositAmount = 19 ether;

    struct TraderStats {
        address trader;
        string traderInfoUri;
        uint256 depositBalance;
        bool varified;
        bool canWithdraw;
        address[] handlingUsers;
    }

    mapping(address => TraderStats) public traderRecords;

    bytes32 private constant VERIFY_TRADER_MESSAGE_HASH = keccak256("VerifyTraderProfile(address _traderAccount, bool verifyStatus)");

    IFundManager private ifundManager;

    constructor() Ownable(msg.sender) EIP712("RegistryTrader", "0.0.1") {}


    // ───────────────────────────────────────────────────────────────
    // ⛔ Custom Errors
    // Description: All revert errors used in RegistryTrader contract
    // Format: CONTRACT_NAME_ERROR___ERROR_NAME()
    // ─────────────────────────────────────────────────────────────── 
    error REGISTRY_TRADER_ERROR___VERIFY_OWNER_SIGNATURE_FAILED();
    error REGISTRY_TRADER_ERROR___TRADER_ALREADY_VERIFIED();

    event REGISTRY_TRADER_EVENT___TRADER_VERIFY(address trader, bool status);

    /// @inheritdoc IRegistryTrader
    function registerTrader(string memory _traderInfoUri) external payable {
        require(msg.value >= traderDepositAmount);
        traderRecords[msg.sender] = TraderStats(
            msg.sender,
            _traderInfoUri,
            msg.value,
            false,
            false,
            new address[](0)
        );
        ifundManager.bindTrader(msg.sender);
    }

    function verifyTraderProfile(
        address _trader,
        bool _status,
        uint8 _owner_v,
        bytes32 _owner_r,
        bytes32 _owner_s
    ) external {
        if (traderRecords[_trader].varified) {
            revert REGISTRY_TRADER_ERROR___TRADER_ALREADY_VERIFIED();
        }
        if (!_verifyOwnerSignature(getMessageHash(_trader, _status), _owner_v, _owner_r, _owner_s)) {
            revert REGISTRY_TRADER_ERROR___VERIFY_OWNER_SIGNATURE_FAILED();
        }
        traderRecords[_trader].varified = _status;   
        emit REGISTRY_TRADER_EVENT___TRADER_VERIFY(_trader, _status);
    }

    function getMessageHash(address _trader, bool _status) public view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(VERIFY_TRADER_MESSAGE_HASH, _trader, _status))
        );
    }

    function _verifyOwnerSignature(bytes32 _digest, uint8 _owner_v, bytes32 _owner_r, bytes32 _owner_s) internal view returns (bool) {
        (address _owner_signer, , ) = ECDSA.tryRecover(_digest, _owner_v, _owner_r, _owner_s);
        return _owner_signer == owner();
    }

    /// @inheritdoc IRegistryTrader
    function unregisterTrader(address _trader) external {
        require(traderRecords[_trader].canWithdraw);
        (bool success, ) = _trader.call{
            value: traderRecords[_trader].depositBalance
        }("");
        require(success);
    }

    function connectRegistryTrader(address _fundmanager) external onlyOwner {
        ifundManager = IFundManager(_fundmanager);
    }
}
