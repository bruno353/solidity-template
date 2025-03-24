// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ChestNFT
 * @notice An ERC721 NFT contract with metadata storage, enumerability, and supply management.
 */
contract ChestNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    /// @dev Tracks the current token ID.
    Counters.Counter private _tokenIds;

    /// @notice Maximum supply (hard cap) of NFTs mintable.
    uint256 public maxSupply;

    /// @notice Structure to hold token-specific metadata.
    struct Item {
        uint256 id;
        uint256 category;
        string uri; // The metadata URI
    }

    /// @notice Map token ID to its Item metadata.
    mapping(uint256 => Item) private _items;

    /// @notice Emitted when a new ChestNFT is minted.
    event NFTMinted(uint256 indexed tokenId, uint256 category, string uri);

    /**
     * @dev Sets contract name, symbol, and maximum supply in constructor.
     * @param _name The ERC721 name.
     * @param _symbol The ERC721 symbol.
     * @param _maxSupply The hard cap for mintable NFTs.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Mint a new NFT with a given URI and category, and assign it to `_to`.
     * @param _to The recipient address of the minted NFT.
     * @param _uri The URI of the NFT metadata.
     * @param _category Numeric category identifier for the NFT.
     * @return newItemId The newly minted token ID.
     */
    function mint(
        address _to,
        string memory _uri,
        uint256 _category
    ) external onlyOwner returns (uint256) {
        require(
            _tokenIds.current() < maxSupply,
            "ChestNFT: Minting would exceed max supply"
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // Mint the token safely
        _safeMint(_to, newItemId);

        // Set metadata URI
        _setTokenURI(newItemId, _uri);

        // Store Item metadata in the contract
        _items[newItemId] = Item({
            id: newItemId,
            category: _category,
            uri: _uri
        });

        emit NFTMinted(newItemId, _category, _uri);
        return newItemId;
    }

    /**
     * @notice Returns the total number of NFTs minted so far.
     */
    function currentSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice Allows the owner to update the maximum supply (if necessary).
     *         Make sure you trust the contract owner fully if you allow changes.
     * @param _newMaxSupply The new max supply to enforce.
     */
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(
            _newMaxSupply >= _tokenIds.current(),
            "ChestNFT: New max supply is below current minted tokens"
        );
        maxSupply = _newMaxSupply;
    }

    /**
     * @notice Updates the token URI post-mint.
     * @param _tokenId The NFT to update.
     * @param _newTokenURI The new metadata URI.
     */
    function setTokenURI(uint256 _tokenId, string memory _newTokenURI)
        external
        onlyOwner
    {
        require(_exists(_tokenId), "ChestNFT: URI set of nonexistent token");
        _setTokenURI(_tokenId, _newTokenURI);
        _items[_tokenId].uri = _newTokenURI;
    }

    /**
     * @notice Retrieves the entire Item struct for the token ID.
     * @dev Reverts if the token does not exist.
     */
    function getItemById(uint256 _tokenId)
        external
        view
        returns (Item memory)
    {
        require(_exists(_tokenId), "ChestNFT: Query for nonexistent token");
        return _items[_tokenId];
    }

    /**
     * @notice Utility function to get an array of all token IDs owned by a specific address.
     * @param _owner The address to query.
     * @return An array of token IDs owned by `_owner`.
     *
     * @dev This is made easier by ERC721Enumerable, which allows `tokenOfOwnerByIndex`.
     *      Be mindful of gas usage if the owner has many tokens.
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
