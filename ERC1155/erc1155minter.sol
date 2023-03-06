// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";


contract CO2 is ERC1155, Ownable, ERC1155Supply, ERC1155Burnable {
    mapping(uint256 => address) public addressToHolder;
    uint256 public holder = 0;

    constructor() ERC1155("https://game.example/api/item/{id}.json") {}

    function mintCO2(address account, uint256 id, uint256 amount) public onlyOwner {

        _mint(account, id, amount, "");

    }
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value) public override onlyOwner {
        _burn(account, id, value);
    }

}
