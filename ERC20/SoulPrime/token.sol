// SPDX-License-Identifier: MIT

/// @title SoulPrime
/// @author Soulprime team
/// @notice Este contrato é para o token SoulPrime.
/// @dev Este contrato cria um token ERC20 e faz a mintagem inicial para um endereço específico.
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SoulPrime is ERC20 {
    /// @notice Cria o token SoulPrime e faz a mintagem inicial.
    /// @dev O total de suprimento é 500 milhões e é enviado para o endereço fornecido no parâmetro do constructor.
    /// @param _address O endereço que receberá os tokens mintados.
    constructor(address _address) ERC20("SoulPrime", "Soul") {
        _mi2nt(_address, 500_000_000 ether);
    }
}
