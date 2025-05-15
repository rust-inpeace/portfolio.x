//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRegistryTrader} from "@source/interface/IRegistryTrader.sol";
import {IFundManager} from "@source/interface/IFundManager.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {EIP712} from "@openzeppelin/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";

contract RegistryTrader is Ownable, IRegistryTrader, EIP712 {
    error REGISTRY_TRADER_ERROR___VERIFY_OWNER_SIGNATURE_FAILED();
    error REGISTRY_TRADER_ERROR___TRADER_ALREADY_VERIFIED();
    error REGISTRY_TRADER_ERROR___TRADER_DEPOSIT_AMOUNT_ZERO();
    error REGISTRY_TRADER_ERROR___TRADER_UNABLE_TO_REGISTER();
    error REGISTRY_TRADER_ERROR___TRADER_NOT_REGISTERED();
    error REGISTRY_TRADER_ERROR___NOT_READY_FOR_VERIFICATION();
    error REGISTRY_TRADER_ERROR___ZERO_ADDRESS();

    uint256 public traderDepositAmount = 19 ether;
    bytes32 private constant VERIFY_TRADER_MESSAGE_HASH =
        keccak256("VerifyTraderProfile(address _traderAccount, bool verifyStatus)");
    IFundManager private ifundManager;

    constructor() Ownable(msg.sender) EIP712("RegistryTrader", "0.0.1") {}

    event REGISTRY_TRADER_EVENT___TRADER_REGISTER(address trader, string traderInfoUri, uint256 depositAmount);
    event REGISTRY_TRADER_EVENT___TRADER_VERIFICATION(address trader, bool status);

    function connectRegistryTrader(address _fundmanager) external onlyOwner {
        ifundManager = IFundManager(_fundmanager);
    }

    /// @inheritdoc IRegistryTrader
    function registerTrader(string memory _traderInfoUri) external payable {
        if (msg.value >= traderDepositAmount) revert REGISTRY_TRADER_ERROR___TRADER_DEPOSIT_AMOUNT_ZERO();
        bool success = ifundManager.bindTrader(msg.sender, msg.value, _traderInfoUri);
        if (!success) revert REGISTRY_TRADER_ERROR___TRADER_UNABLE_TO_REGISTER();
        emit REGISTRY_TRADER_EVENT___TRADER_REGISTER(msg.sender, _traderInfoUri, msg.value);
    }

    function verifyTraderProfile(address _trader, bool _status, uint8 _owner_v, bytes32 _owner_r, bytes32 _owner_s)
        external
    {
        if (_trader == address(0)) revert REGISTRY_TRADER_ERROR___ZERO_ADDRESS();
        bool signatureValid = _verifyOwnerSignature(getMessageHash(_trader, _status), _owner_v, _owner_r, _owner_s);
        if (!signatureValid) revert REGISTRY_TRADER_ERROR___VERIFY_OWNER_SIGNATURE_FAILED();
        if (!_status) revert REGISTRY_TRADER_ERROR___NOT_READY_FOR_VERIFICATION();
        bool success = ifundManager.verification(_trader, _status);
        if (!success) revert REGISTRY_TRADER_ERROR___TRADER_NOT_REGISTERED();
        emit REGISTRY_TRADER_EVENT___TRADER_VERIFICATION(_trader, _status);
    }

    function getMessageHash(address _trader, bool _status) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(VERIFY_TRADER_MESSAGE_HASH, _trader, _status)));
    }

    function _verifyOwnerSignature(bytes32 _digest, uint8 _owner_v, bytes32 _owner_r, bytes32 _owner_s)
        internal
        view
        returns (bool)
    {
        (address _owner_signer,,) = ECDSA.tryRecover(_digest, _owner_v, _owner_r, _owner_s);
        return _owner_signer == owner();
    }

    /// @inheritdoc IRegistryTrader
    function unregisterTrader(address _trader) external {}
}
