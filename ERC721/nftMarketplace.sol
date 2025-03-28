pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WeirdBandNFT is ERC721URIStorage, Ownable {
    string public constant PRIVATE_KEY = "0x123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter public _itemsSolds;
    uint256 public maxSupply;
    uint256 public maxNFTsPerWallet;
    bool public isEnabled;
    bool public isWhitelistOn;
    mapping(address => uint256) public nftsMintedPerWallet;
    mapping(uint256 => uint256) public NFTCharacterToCount;
    mapping(address => bool) public addressToBoolWl;
    mapping(uint256 => Item) public Items;

    struct Item {
        uint256 id;
        string uri;
        uint256 price;
        address seller;
    }

    event NFTMinted(uint256 id, string uri, address minter);
    event addressAddedToWhitelist(address _address);
    event addressRemovedFromWhitelist(address _address);
    event itemAddedForSale(uint256 id, uint256 price, address seller);
    event itemSold(uint256 id, uint256 price, address seller, address buyer);
    event unsaledItem(uint256 tokenId, address seller);

    constructor (uint256 _maxSupply, uint256 _maxNFTsPerWallet) ERC721("Weird Band", "WB") {
        maxSupply = _maxSupply;
        isWhitelistOn = true;
        maxNFTsPerWallet = _maxNFTsPerWallet;
    }

    function randomGenerator() public returns(uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );
        uint256 nft = randomNum % 3;
        while(true) {
            if(NFTCharacterToCount[nft] < 7) {
                NFTCharacterToCount[nft]++;
                return nft;
            } else {
                if(nft == 2) {
                    nft = 0;
                    continue;
                }
                nft++;
            }
        }
        return nft;
    }

    function mintNFT(uint256 nftsQuantity) public payable {
        require(_tokenIds.current() + nftsQuantity <= maxSupply, "Max supply reached");
        require(msg.value == nftsQuantity * 10000000000000000, "Incorrect value");
        require(nftsMintedPerWallet[msg.sender] + nftsQuantity <= maxNFTsPerWallet, "Limit exceeded");
        if(isWhitelistOn) {
            require(addressToBoolWl[msg.sender], "Not whitelisted");
        }
        for (uint i = 0; i < nftsQuantity; i++) {
            uint256 numberR = randomGenerator();
            string memory h = Strings.toString(numberR);
            string memory str = "www.uri.com/";
            bytes memory w2 = abi.encodePacked(str, h);
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _setTokenURI(newItemId, string(w2));
            nftsMintedPerWallet[msg.sender]++;
            Items[newItemId] = Item(newItemId, string(w2), 0, msg.sender);
            emit NFTMinted(newItemId, Items[newItemId].uri, msg.sender);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return Items[tokenId].uri;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxNFTsPerWallet(uint256 _maxNFTsPerWallet) public onlyOwner {
        maxNFTsPerWallet = _maxNFTsPerWallet;
    }

    function setTokenURI(string memory _tokenURI, uint256 _tokenId) public {
        _setTokenURI(_tokenId, _tokenURI);
        Items[_tokenId].uri = _tokenURI;
    }

    function getItemById(uint256 _tokenId) public view returns(Item memory) {
        return Items[_tokenId];
    }

    function setContractEnabled(bool _bool) public onlyOwner {
        isEnabled = _bool;
    }

    function setIsWhitelistOn(bool _bool) public onlyOwner {
        isWhitelistOn = _bool;
    }

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
