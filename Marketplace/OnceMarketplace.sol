// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OnceToken.sol";

//to do: How to integrate in the minting function an Id card (but with privacy), so we know when someone dies but without exposing who it is to the blockchain?
//set a function: When the 10/5 years has passed and the person has not died, the payout backed is returned to the Insurance company.
//set a function: When the insured dies, who owns the NFT is paid with the total amount backed. -> this function can be set into the marketplace contract?

contract OnceMarketplace is OnceToken {

  //With the listingPrice we can set a lot of things, like paying comissions for the first owner of that nft or setting a fee for the Once pool
  //so every time an NFT is traded/listed a fee goes to that pool.

  //Setting the owner address so it can be paid every time a NFT is traded/listed in the (basicaly a comission for our Once pool)
  //I believe in the future this address will be a DAO
  address ownerPool = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

  

  // Updates the listing price of the contract (this only can be set by the pool owner) 
  function updateListingPrice(uint _listingPrice) public payable {
    require(ownerool == msg.sender, "Only pool owner can update it");
  }

  // Returns the listing price of the contract 
  function getListingPrice() public view returns (uint256) {
    return listinPrice;
  }

  struct ItemForSale {
    uint256 id;
    uint256 tokenId;
    address payable seller;
    uint256 price;
    bool isSold;
  }

  ItemForSale[] public itemsForSale;
  mapping(uint256 => bool) public activeItems;

  event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
  event itemSold(uint256 id, address buyer, uint256 price);

  constructor(OnceToken _token) {
      token = _token;
  }

  modifier OnlyItemOwner(uint256 tokenId){
    require(token.ownerOf(tokenId) == msg.sender, "Sender does not own the item");
    _;
  }

  modifier HasTransferApproval(uint256 tokenId){
    require(token.getApproved(tokenId) == address(this), "Market is not approved");
    _;
  }

  modifier ItemExists(uint256 id){
    _;
  }

  modifier IsForSale(uint256 id){
    require(!itemsForSale[id].isSold, "Item is already sold");
    _;
  }
  function fetchNFT(uint256 tokenId) public view returns (Item memory){
      return Items[tokenId];
  }

  function putItemForSale(uint256 tokenId, uint256 price) 
    external 
    payable
    returns (uint256){
      require(!activeItems[tokenId], "Item is already up for sale");
      require(msg.value == listingPrice, "Price must be equal to listing price");
      require(Items[tokenId].backed == true, "This NFT was not backed yet");

      uint256 newItemId = itemsForSale.length;
      itemsForSale.push(ItemForSale({
        id: newItemId,
        tokenId: tokenId,
        seller: payable(msg.sender),
        price: price,
        isSold: false
      }));
      activeItems[tokenId] = true;

      assert(itemsForSale[newItemId].id == newItemId);
      emit itemAddedForSale(newItemId, tokenId, price);
      return newItemId;
  }


  // Creates the sale of a marketplace item 
  // Transfers ownership of the item, as well as funds between parties (and gives a little of fees for the Once pool if we want)
  // I need to check if this is okay, here we give the listingPrice for our pool, as the nft was sold.
  function buyItem(uint256 id) 
    ItemExists(id)
    IsForSale(id)
    HasTransferApproval(itemsForSale[id].tokenId)
    payable 
    external {
      require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
      require(msg.sender != itemsForSale[id].seller);

      itemsForSale[id].isSold = true;
      activeItems[itemsForSale[id].tokenId] = false;
      token.safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId);
      itemsForSale[id].seller.transfer(msg.value);
      payable(ownerPool).transfer(listingPrice);

      emit itemSold(id, msg.sender, itemsForSale[id].price);
    }

  function totalItemsForSale() public view returns(uint256) {
    return itemsForSale.length;
  }
  
  function fetchMarketItems() public view returns (ItemForSale[] memory){
      uint itemCount = _tokenIds.current();
      uint unsoldItemCount = totalItemsForSale();
      uint currentIndex = 0;

      ItemForSale[] memory items = new ItemForSale[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
          if (itemsForSale[i + 1].isSold == false) {
              uint currentId = i + 1;
              ItemForSale storage currentItem = itemsForSale[currentId];
              items[currentIndex] = currentItem;
              currentIndex += 11;
          }
      }
    return items;
  }

  
}
