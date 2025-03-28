pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WeirdBandNFT is ERC721URIStorage, Ownable {

    function addAddressToWhitelist(address _address) public onlyOwner {
        addressToBoolWl[_address] = true;
        emit addressAddedToWhitelist(_address);
    }

    function removeAddressFromWhitelist(address _address) public onlyOwner {
        addressToBoolWl[_address] = false;
        emit addressRemovedFromWhitelist(_address);
    }

    function putItemForSale(uint256 _tokenId, uint256 _price) external payable {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(_price > 0 , "Price must be > 0");
        Items[_tokenId].price = _price;
        Items[_tokenId].seller = msg.sender;
        _transfer(msg.sender, address(this), _tokenId);
        emit itemAddedForSale(_tokenId, _price, msg.sender);
    }

    function buyItem(uint256 _tokenId) payable external {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
		require(ownerOf(_tokenId) == address(this), "Not for sale");
        require(msg.value >= Items[_tokenId].price, "Insufficient funds");
        require(msg.sender != Items[_tokenId].seller, "Seller can't buy");
        uint256 priceEmit = Items[_tokenId].price;
        Items[_tokenId].price = 0;
        _transfer(address(this), msg.sender, _tokenId);
        payable(Items[_tokenId].seller).transfer((msg.value * 97) / 100);
        _itemsSolds.increment();
        emit itemSold(_tokenId, priceEmit, Items[_tokenId].seller, msg.sender);
    }

    function unsaleItem(uint256 _tokenId) payable external {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
		require(ownerOf(_tokenId) == address(this), "Not for sale");
        require(msg.sender == Items[_tokenId].seller, "Not seller");
        Items[_tokenId].price = 0;
        _transfer(address(this), msg.sender, _tokenId);
        emit unsaledItem(_tokenId, msg.sender);
    }

    function fundMe() public payable returns(uint256) {
        return msg.value;
    }
}
