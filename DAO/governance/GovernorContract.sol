// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";

/**
 * @title GovernorContract
 * @dev Contract that handles governance using OpenZeppelin's Governor extensions
 * @notice This contract combines various governor modules for voting, counting, timing and execution
 */
contract GovernorContract is
  Governor,
  GovernorSettings,
  GovernorCountingSimple,
  GovernorVotes,
  GovernorVotesQuorumFraction,
  GovernorTimelockControl
{
  /**
   * @dev Constructor for the governance contract
   * @param _token The token used for voting
   * @param _timelock The timelock controller used for proposal execution
   * @param _quorumPercentage The percentage of the total supply needed for a quorum
   * @param _votingPeriod The period in blocks during which voting is possible
   * @param _votingDelay The delay in blocks before voting on a proposal can start
   */
  constructor(
    IVotes _token,
    TimelockController _timelock,
    uint256 _quorumPercentage,
    uint256 _votingPeriod,
    uint256 _votingDelay
  )
    Governor("GovernorContract")
    GovernorSettings(
      _votingDelay, // voting delay in blocks
      _votingPeriod, // voting period in blocks
      0 // proposal threshold - 0 tokens needed to propose
    )
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(_quorumPercentage)
    GovernorTimelockControl(_timelock)
  {}

  /**
   * @dev Returns the delay in blocks before voting on a newly created proposal starts
   * @return The voting delay in blocks
   */
  function votingDelay()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingDelay();
  }

  /**
   * @dev Returns the duration in blocks of the voting period
   * @return The voting period in blocks
   */
  function votingPeriod()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingPeriod();
  }

  /**
   * @dev Returns the minimum number of votes needed for a quorum
   * @param blockNumber The block number to get the quorum for
   * @return The minimum number of votes needed
   */
  function quorum(uint256 blockNumber)
    public
    view
    override(IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  /**
   * @dev Returns the voting power of an account at a specific block number
   * @param account The address to get votes for
   * @param blockNumber The block number to get the votes at
   * @return The number of votes the account had at the given block
   */
  function getVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernor, Governor)
    returns (uint256)
  {
    return super.getVotes(account, blockNumber);
  }

  /**
   * @dev Returns the state of a proposal
   * @param proposalId The ID of the proposal
   * @return The current state of the proposal
   */
  function state(uint256 proposalId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  /**
   * @dev Creates a new proposal
   * @param targets The addresses to call
   * @param values The ETH values to send with the calls
   * @param calldatas The calldata to send with the calls
   * @param description The description of the proposal
   * @return The ID of the newly created proposal
   */
  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  ) public override(Governor, IGovernor) returns (uint256) {
    return super.propose(targets, values, calldatas, description);
  }

  /**
   * @dev Returns the minimum number of votes needed to create a proposal
   * @return The proposal threshold
   */
  function proposalThreshold()
    public
    view
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  /**
   * @dev Executes a successful proposal
   * @param proposalId The ID of the proposal to execute
   * @param targets The addresses to call
   * @param values The ETH values to send with the calls
   * @param calldatas The calldata to send with the calls
   * @param descriptionHash The hash of the proposal description
   */
  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  /**
   * @dev Cancels a proposal
   * @param targets The addresses that would be called
   * @param values The ETH values that would be sent
   * @param calldatas The calldata that would be sent
   * @param descriptionHash The hash of the proposal description
   * @return The ID of the canceled proposal
   */
  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  /**
   * @dev Returns the address of the executor for this contract
   * @return The executor address
   */
  function _executor()
    internal
    view
    override(Governor, GovernorTimelockControl)
    returns (address)
  {
    return super._executor();
  }

  /**
   * @dev Checks if the contract supports an interface
   * @param interfaceId The interface ID to check
   * @return True if the interface is supported
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
