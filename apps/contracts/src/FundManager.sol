//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";

contract FundManager is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    error FundManager__TokenIsNotAllowed();

    mapping(address => mapping(address => uint256)) public userDeposit;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 private tokenMerkleRoot;

    /// @notice Emitted When user deposit token
    event FundManager__UserTokenDeposit(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    constructor(bytes32 _tokenMerkleRoot) Ownable(msg.sender) {
        tokenMerkleRoot = _tokenMerkleRoot;
    }

    function updateMerkleRoot(bytes32 _tokenMerkleRoot) external onlyOwner {
        tokenMerkleRoot = _tokenMerkleRoot;
    }



    function deposit(
        address _token,
        uint256 _amount,
        bytes32[] calldata _proofs
    ) external payable nonReentrant {
        require(_amount > 0);
        if (_token == ETH_ADDRESS && msg.value == _amount) {
            userDeposit[msg.sender][_token] += msg.value;
        } else {
            bytes32 leaf = keccak256(
                bytes.concat(keccak256(abi.encode(_token)))
            );

            if (!MerkleProof.verify(_proofs, tokenMerkleRoot, leaf)) {
                revert FundManager__TokenIsNotAllowed();
            }
            require(msg.value == 0);
            userDeposit[msg.sender][_token] += _amount;
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit FundManager__UserTokenDeposit(msg.sender, _token, _amount);
    }
}
