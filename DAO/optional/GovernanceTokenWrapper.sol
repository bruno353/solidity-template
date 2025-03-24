// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

/**
 * @title GovernanceTokenWrapper
 * @dev Implementation of a governance token wrapper that adds voting capabilities to an existing ERC20 token
 * @notice This contract allows wrapping any ERC20 token to add governance capabilities
 */
contract GovernanceTokenWrapper is ERC20, ERC20Permit, ERC20Votes, ERC20Wrapper {
  /**
   * @dev Initializes the wrapper with the token to be wrapped
   * @param wrappedToken The ERC20 token to be wrapped
   */
  constructor(IERC20 wrappedToken)
    ERC20("GovernanceTokenWrapper", "GTW")
    ERC20Permit("GovernanceTokenWrapper")
    ERC20Wrapper(wrappedToken)
  {}

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
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens
   * @param amount The amount of tokens to mint
   * @notice Mandatory override for ERC20Votes to update vote checkpoints
   */
  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  /**
   * @dev Function to burn tokens
   * @param account The account whose tokens will be burnt
   * @param amount The amount of tokens to burn
   * @notice Mandatory override for ERC20Votes to update vote checkpoints
   */
  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }

  /**
   * @dev Returns the number of decimals of the token
   * @return The number of decimals
   * @notice This function is overridden to ensure compatibility with the wrapped token
   */
  function decimals() public view override(ERC20, ERC20Wrapper) returns (uint8) {
    return super.decimals();
  }
}
