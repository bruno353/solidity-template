// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract ChestNFT is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;
    address public ownerGovernance;
    uint256 maxSupply;


    constructor (uint256 _maxSupply) ERC721("Chest-NFT", "TBT") {
            ownerGovernance = msg.sender;
            maxSupply = _maxSupply;
    }

    //Creating the nfts struct:
    struct Item {
        uint256 id;
        uint256 category;
        string uri;//metadata url
    }

    event NFTMinted (uint256 id, uint256 category, string uri);

    mapping(uint256 => Item) public Items; //id => Item

    function mint(string memory uri, uint256 _category, address _address) public payable returns(uint256){
        require(_tokenIds.current() < maxSupply, "The minting process reached the max supply");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_address, newItemId);
        approve(address(this), newItemId);
        _setTokenURI(newItemId, uri);
        
        Items[newItemId] = Item({
        id: newItemId, 
        category: _category,
        uri: uri
        });

        emit NFTMinted(Items[newItemId].id, Items[newItemId].category, Items[newItemId].uri);
        return newItemId;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return Items[tokenId].uri;
    }

    function currentSupply() public onlyOwner view returns(uint256) {
        return _tokenIds.current();

        }
    
    function setOwnerGovernance(address _address) public {
        ownerGovernance = _address;
    }

    function setMaxSupply(uint256 _maxSupply) public {
        require(msg.sender == ownerGovernance, "Only the ownerGovernance can change it");
        maxSupply = _maxSupply;
    }

    function setTokenURI(string memory _tokenURI, uint256 _tokenId) public {
        _setTokenURI(_tokenId, _tokenURI);
        Items[_tokenId].uri = _tokenURI;
    }

    function getItemById(uint256 _tokenId) public view returns(Item memory){
        return Items[_tokenId];
    }


}
