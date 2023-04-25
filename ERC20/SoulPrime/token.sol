// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    //Passar o address do contrato de vesting - mintando 500 milhões de tokens.
    constructor(address _address) ERC20("SoulPrime", "Soul") {
        _mint(_address, 500_000_000_000000000000000000);
    }
}
