// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Box
 * @dev A simple contract for storing and retrieving a uint256 value.
 *      Inherits from Ownable, so only the owner can update the value.
 */
contract Box is Ownable {
    uint256 private _value;

    /**
     * @dev Emitted when the stored value changes.
     * @param newValue The new value that was stored
     */
    event ValueChanged(uint256 newValue);

    /**
     * @dev Stores a new value in the contract.
     * @param newValue The new value to store.
     * @notice This function is restricted to the contract owner.
     */
    function storeValue(uint256 newValue) public onlyOwner {
        _value = newValue;
        emit ValueChanged(newValue);
    }

    /**
     * @dev Reads the last stored value.
     * @return The last stored value.
     */
    function retrieve() public view returns (uint256) {
        return _value;
    }
}
