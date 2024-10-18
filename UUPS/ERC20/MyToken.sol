// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //tokens de captação que vão poder transferir tokens CL;
    mapping(address => bool) public allowedAddress;

    modifier onlyAllowed() {
        require(msg.sender == owner() || allowedAddress[msg.sender] == true);
        _;
    }

    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function setAllowedAddress(address _address, bool _bool) public onlyOwner {
        allowedAddress[_address] = _bool;
    }


    function transfer(address to, uint256 amount) public override onlyAllowed returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override onlyAllowed returns (bool) {
        _transfer(from, to, amount);
        return true;
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
