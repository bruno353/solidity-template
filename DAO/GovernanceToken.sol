// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title governancetoken
 * @notice erc20 token with governance capabilities using erc20votes
 */
contract GovernanceToken is ERC20Votes {
    // maximum supply of tokens (1e24 tokens)
    uint256 public constant MAX_SUPPLY = 1000000000000000000000000;

    /**
     * @notice constructor that mints the total supply to the deployer
     */
    constructor() ERC20("GovernanceToken", "GT") ERC20Permit("GovernanceToken") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    /**
     * @notice hook called after any transfer of tokens
     * @dev required override for erc20votes
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @notice mints tokens to a specified address
     * @dev required override for erc20votes
     */
    function _mint(address to, uint256 amount) internal override {
        super._mint(to, amount);
    }

    /**
     * @notice burns tokens from a specified account
     * @dev required override for erc20votes
     */
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
    }
}
