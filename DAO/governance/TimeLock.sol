// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title TimeLock
 * @dev A timelock mechanism for governance actions
 * @notice This contract adds a time delay to governance actions for security
 */
contract TimeLock is TimelockController {
  /**
   * @dev Initializes the contract with the required parameters
   * @param minDelay The minimum delay before execution (in seconds)
   * @param proposers The list of addresses that can propose timelock actions
   * @param executors The list of addresses that can execute timelock actions
   */
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) TimelockController(minDelay, proposers, executors) {}
}
