// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Proxiable.sol";

contract MyContract is Proxiable {
    address public owner;
    uint256 public count;
    bool public initialized;

    /**
     * @notice Initializes the contract, setting the deployer as owner.
     *         Can only be called once.
     */
    function initialize() external {
        require(!initialized, "Already initialized");
        owner = msg.sender;
        initialized = true;
    }

    /**
     * @notice Increments the counter by 1.
     */
    function increment() external {
        count++;
    }

    /**
     * @notice Updates the implementation address for this proxy.
     *         Only the contract owner can call this function.
     * @param newCode The address of the new implementation contract.
     */
    function updateCode(address newCode) external onlyOwner {
        require(newCode != address(0), "Invalid code address");
        updateCodeAddress(newCode);
    }

    /**
     * @notice Allows the current owner to transfer control of the contract
     *         to a new owner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
}
