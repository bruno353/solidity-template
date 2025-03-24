// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CO2Token
 * @dev Contrato ERC1155 com funcionalidades de mint, burn e controle de supply.
 *      Permite o ajuste dinâmico do URI base, se necessário.
 */
contract CO2Token is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable {
    /**
     * @notice Emite quando o URI base é atualizado.
     * @param newURI O novo URI base que foi definido.
     */
    event BaseURIUpdated(string newURI);

    /**
     * @dev Construtor do contrato, definindo um URI base para os metadados dos tokens.
     * @param _initialURI URI base padrão para os tokens.
     */
    constructor(string memory _initialURI) ERC1155(_initialURI) {}

    /**
     * @dev Função para atualizar o URI base. Somente o proprietário pode chamar.
     * @param _newURI Novo URI base para os metadados de token.
     */
    function setURI(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
        emit BaseURIUpdated(_newURI);
    }

    /**
     * @notice Cria ("mint") novos tokens CO2 para um endereço específico.
     * @dev Somente o proprietário do contrato pode chamar esta função.
     * @param account Endereço que receberá os tokens.
     * @param id Identificador do token a ser criado.
     * @param amount Quantidade de tokens a serem criados.
     */
    function mintCO2(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(account, id, amount, "");
    }

    /**
     * @notice Queima tokens de uma conta específica.
     * @dev Somente o proprietário do contrato pode chamar esta função.
     * @param account Endereço do qual os tokens serão queimados.
     * @param id Identificador do token a ser queimado.
     * @param value Quantidade de tokens a serem queimados.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public override onlyOwner {
        _burn(account, id, value);
    }

    /**
     * @notice Queima múltiplos tipos de tokens de uma conta específica em uma única chamada.
     * @dev Somente o proprietário do contrato pode chamar esta função.
     * @param account Endereço do qual os tokens serão queimados.
     * @param ids Lista de identificadores de tokens a serem queimados.
     * @param values Lista de quantidades de cada token a serem queimadas.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override onlyOwner {
        _burnBatch(account, ids, values);
    }

    /**
     * @dev Hook chamado antes de qualquer transferência de token (mint, burn, transferência).
     *      Necessário para manter a compatibilidade com o ERC1155Supply.
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
}
