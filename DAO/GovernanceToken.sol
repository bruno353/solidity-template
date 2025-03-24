// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title GovernanceToken
 * @dev Implementation of a governance token using OpenZeppelin's ERC20Votes extension
 * @notice This token enables on-chain governance with checkpointing capabilities
 */
contract GovernanceToken is ERC20Votes {
    // Maximum supply of tokens (1 million tokens with 18 decimals = 1e24 wei)
    uint256 public constant MAX_SUPPLY = 1_000_000_000_000_000_000_000_000;

    /**
     * @dev Initializes the contract with name, symbol and mints the total supply to the deployer
     */
    constructor() ERC20("GovernanceToken", "GT") ERC20Permit("GovernanceToken") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    /**
     * @dev Hook called after any transfer of tokens
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param amount The amount of tokens transferred
     * @notice Mandatory override for ERC20Votes to update vote checkpoints
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     * @notice Mandatory override for ERC20Votes to update vote checkpoints
     */
    function _mint(address to, uint256 amount) internal override {
        super._mint(to, amount);
    }

    /**
     * @dev Function to burn tokens
     * @param account The account whose tokens will be burnt
     * @param amount The amount of tokens to burn
     * @notice Mandatory override for ERC20Votes to update vote checkpoints
     */
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
    }
}
