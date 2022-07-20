// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SampleERC721
 * @dev Create a sample ERC721 standard token
 */
contract SampleERC721 is ERC721URIStorage {
  using Counters for Counters.Counter;

  Counters.Counter public _tokenIds;
  Counters.Counter public _itemsSold;

  constructor () ERC721("Extra-Life", "LIFE") {
  }

  //setting a governance oracle/DAO that will grants access for minting Once NFTs
  //So who pass the Once KYC system will have the permission for minting:
  address public ownerGovernance = 0x08ADb3400E48cACb7d5a5CB386877B3A159d525C;

  //Creating the insured structs:
  struct Insured {
    uint256 id;
    address insured;
  }

  mapping(uint256 => Insured) public Insureds;
  

  //Creating the nfts struct:
  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
    //premium for insurance
    uint256 premium;
    //boolean for knowing if the nft was backed or not:
    bool backed;
    //the amount of money the insured wants to be backed for his premium, in case of death who owns the nfts can claim the reward:
    uint256 payout;
    //who backs this nft will be the insurer
    address insurer;
    //if the assurance was already called, if so this nft does not own more value:
    bool assuranceTriggered;
  }

  event NFTMinted (uint256 id, address creator, string uri, uint256 premium, bool backed, uint256 payout);

  mapping(uint256 => Item) public Items; //id => Item

  

  //when minting the user pass the uri, the premium (its the msg.value) and the amount the wants in case of dead (payout)
  function mint(string memory uri, uint256 _payout) public payable returns (uint256){
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(address(this), newItemId);
    _setTokenURI(newItemId, uri);
    
    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri,
      premium: msg.value,
      backed: false,
      payout: _payout,
      insurer: msg.sender,
      assuranceTriggered: false
    });

    emit NFTMinted(Items[newItemId].id, Items[newItemId].creator, Items[newItemId].uri, Items[newItemId].premium, Items[newItemId].backed, Items[newItemId].payout);
    return newItemId;
  }


  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  function fetchPayoutAmount(uint256 tokenId) public view returns (uint256){
    return Items[tokenId].payout;
  }


    //MARKETPLACE:

    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        uint256 payout;
        bool isSold;
    }

    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;
    mapping(uint256 => ItemForSale) private idToMarketItem;


    event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price, address seller, bool sold, uint256 payoutAmount);
    event itemSold(uint256 id, address buyer, uint256 price, bool sold, uint256 payoutAmount);   



    modifier IsForSale(uint256 id){
        require(!itemsForSale[id].isSold, "Item is already sold");
        _;
    }

    modifier ItemExists(uint256 id){
        require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find item");
        _;
  }


    function putItemForSale(uint256 tokenId, uint256 price) 
        external 
        payable
        returns (uint256){
        require(!activeItems[tokenId], "Item is already up for sale");
        require(Items[tokenId].backed == true, "This NFT was not backed yet");
        require(ownerOf(tokenId) == msg.sender, "You are not the token owner");

        uint256 newItemId = itemsForSale.length;
        itemsForSale.push(ItemForSale({
            id: newItemId,
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            payout: Items[tokenId].payout,
            isSold: false
        }));
        activeItems[tokenId] = true;

        _transfer(msg.sender, address(this), tokenId);

        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAddedForSale(newItemId, tokenId, price, msg.sender, false, Items[tokenId].payout);
        return newItemId;
    }

    // Creates the sale of a marketplace item 
    // Transfers ownership of the item, as well as funds between parties (and gives a little of fees for the Once pool if we want)
    // I need to check if this is okay, here we give the listingPrice for our pool, as the nft was sold.
    function buyItem(uint256 id) 
        ItemExists(id)
        IsForSale(id)
        payable 
        external {
        require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenId] = false;

        _transfer(address(this), msg.sender, itemsForSale[id].tokenId);
        
        payable(itemsForSale[id].seller).transfer(msg.value);

        _itemsSold.increment();

        emit itemSold(id, msg.sender, itemsForSale[id].price, true, itemsForSale[id].payout);
        }

    function totalItemsForSale() public view returns(uint256) {
        return itemsForSale.length;
    }

}
