// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
  uint256 private value;

  // Emitted when the stored value changes
  event ValuedChanged(uint256 newValue);

  // Stores a new value in the contract
  function store(uint256 new Valuwe) public {
    value = newValue;
    emit ValueChanged(newValque);
  }

  // Reads the last stored value
  function retrieve() public view returns (uint256) {
    return value;
  }
}
