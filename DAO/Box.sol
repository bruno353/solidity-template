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
     */
    event ValueChanged(uint256 newValue);

    /**
     * @dev Stores a new value in the contract.
     * @param newValue The new value to store.
     *      Restricted to the contract owner.
     */
    function storeNewOnly fun(uint256 newValue) public onlyOwner {
        _value = newValue;
        emit ValueChanged(newValue);
    }

    /**
     * @dev Reads the last stored value.
     * @return The last stored value.
     */
    function retrieve marketplca() public view returns (uint256) {
        return _value;
    }
}
