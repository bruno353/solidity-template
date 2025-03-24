// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WhitelistedERC20
 * @dev ERC20 token that restricts token transfers to whitelisted addresses.
 */
contract WhitelistedERC20 is ERC20, Ownable {

    /// @notice Mapping to track which addresses are whitelisted.
    mapping(address => bool) public whitelist;

    /// @notice Emitted when an address's whitelist status is updated.
    event WhitelistUpdated(address indexed account, bool status);

    /**
     * @dev Mints initial supply to the contract deployer.
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _initialSupply Initial token supply (in wei). 
     *        Example: If you want 1,000 tokens and each token has 18 decimals,
     *        pass 1000 * 10^18 = 1000000000000000000000.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }

    /**
     * @dev Updates the whitelist status for a specific address.
     * @param _account The address to update.
     * @param _status True if the address is whitelisted, false otherwise.
     */
    function setWhitelistStatus(address _account, bool _status) external onlyOwner {
        whitelist[_account] = _status;
        emit WhitelistUpdated(_account, _status);
    }

    /**
     * @dev Overrides ERC20 transfer to require the recipient address be whitelisted.
     * @param to The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(whitelist[to], "Transfer to non-whitelisted address");
        return super.transfer(to, amount);
    }

    /**
     * @dev Overrides ERC20 transferFrom to require the recipient address be whitelisted.
     * @param from The address which is sending the tokens.
     * @param to The address which is receiving the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(whitelist[to], "Transfer to non-whitelisted address");
        return super.transferFrom(from, to, amount);
    }
}
