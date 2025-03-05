// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/**
 * @title CO2 Token Contract
 * @dev Contrato ERC1155 que inclui funcionalidades de mint, burn e controle de supply.
 */
contract CO2 is ERC1155, Ownable, ERC1155Supply, ERC1155Burnable {
    /**
     * @dev Construtor que define o URI base para os metadados dos tokens.
     */
    constructor() ERC1155("https://game.example/api/item/{id}.json") {}

    /**
     * @notice Mint de novos tokens.
     * @dev Apenas o proprietário do contrato pode chamar esta função.
     * @param account Endereço que receberá os tokens.
     * @param id Identificador do token a ser mintado.
     * @param amount Quantidade de tokens a ser mintada.
     */
    function mintCO2(address account, uint256 id, uint256 amount) external onlyOwner {
        _mint(account, id, amount, "");
    }

    /**
     * @dev Hook que é chamado antes de qualquer transferência de token.
     * Necessário para compatibilidade com o ERC1155Supply.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Queima tokens de uma conta específica.
     * @dev Apenas o proprietário do contrato pode chamar esta função.
     * @param account Endereço do qual os tokens serão queimados.
     * @param id Identificador do token a ser queimado.
     * @param value Quantidade de tokens a serem queimados.
     */
    function burn(address account, uint256 id, uint256 value) public override onlyOwner {
        _burn(account, id, value);
    }
}
