// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract Gantier is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;
    Counters.Counter public _itemsSolds;
    Counters.Counter public _NFTsMintedByOwner;
    uint256 public maxSupply = 3333;
    uint256 public marketplaceFee = 3;  // base 100 - 3 igual a 3%
    bool public isEnabled;

    // Ambos possuem 6 casas decimais
    IERC20 public USDCAddress;
    IERC20 public USDTAddress;

    //Se o usuário deseja receber em MATIC ou em USD
    enum PaymentType {
        Matic,
        USD
    }

    mapping(uint256 => mapping(address => uint256)) public nftsMintedPerWallet;
    mapping(uint256 => string) public NFTCharacterToURI;

    struct Item {
        uint256 id;
        uint256 price;
        address seller;
        PaymentType paymentType;
    }
    mapping(uint256 => Item) public Items; //id => Item

    constructor (address _USDCAddress, address _USDTAddress, uint256 _marketplaceFee) ERC721("Gantier", "GA")  {
        USDCAddress = IERC20(_USDCAddress);
        USDTAddress = IERC20(_USDTAddress);
        marketplaceFee = _marketplaceFee;
    }
    
    function setTokensAddress(address _USDCAddress, address _USDTAddress) public onlyOwner() {
        USDCAddress = IERC20(_USDCAddress);
        USDTAddress = IERC20(_USDTAddress);
    }

    event NFTMinted (uint256 id, string uri, address minter);

    function mintNFT(string[] memory _uris, address _to) public onlyOwner {
        require(isEnabled, "The contract is not enabled");
    
        for (uint i = 0; i < _uris.length; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            _safeMint(_to, newItemId);
            _setTokenURI(newItemId, _uris[i]);

            Items[newItemId] = Item({
            id: newItemId, 
            price: 0,
            seller: _to,
            paymentType: PaymentType(0)
            });
        }
    }

    function setTokenURI(string memory _tokenURI, uint256 _tokenId) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setContractEnabled(bool _bool) public onlyOwner {
        isEnabled = _bool;
    }

    function setURIs( uint256[] memory _nftsArray, string[] memory _nftsURIs) public onlyOwner {
        for (uint i = 0; i < _nftsArray.length; i++) { 
            _setTokenURI(_nftsArray[i], _nftsURIs[i]);
        }
    }

    //MARKETPLACE:
    event itemAddedForSale(uint256 id, uint256 price, address seller);
    event itemSold(uint256 id, uint256 price, address seller, address buyer, PaymentType _paymentType);  


    function putItemForSale(uint256 _tokenId, uint256 _price, PaymentType _paymentType)
        external 
        payable {
        require(ownerOf(_tokenId) == msg.sender, "You are not the token owner");
        require(_price > 0 , "Price needs to be greater than 0");

        Items[_tokenId].price = _price;
        Items[_tokenId].seller = msg.sender;
        Items[_tokenId].paymentType = _paymentType;

        _transfer(msg.sender, address(this), _tokenId);

        emit itemAddedForSale(_tokenId, _price, msg.sender);
    }

    // Creates the sale of a marketplace item 

    // Funcao parta comprar nfts que estao a venda por matic
    function buyItemWithMatic(uint256 _tokenId) 
        payable 
        external nonReentrant  {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
		require(ownerOf(_tokenId) == address(this), "Token not for sale");
        require(msg.value >= Items[_tokenId].price, "Not enough funds sent");
        require(msg.sender != Items[_tokenId].seller, "The seller can not buy it");
        require(Items[_tokenId].paymentType == PaymentType(0), "This item is not for Matic sale");
    
        uint256 priceEmit = Items[_tokenId].price;

        Items[_tokenId].price = 0;


        _transfer(address(this), msg.sender, _tokenId);
        
        //3% of royalties
        payable(Items[_tokenId].seller).transfer(msg.value * 97/100);

        _itemsSolds.increment();

        emit itemSold(_tokenId, priceEmit, Items[_tokenId].seller, msg.sender, PaymentType(0));

        }

    
    enum USDPaymentType {
        USDC,
        USDT
    }

    // Funcao parta comprar nfts que estao a venda por usd
    function buyItemWithUSD(uint256 _tokenId, USDPaymentType _USDPaymentType) 
        external nonReentrant  {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
		require(ownerOf(_tokenId) == address(this), "Token not for sale");
        require(msg.sender != Items[_tokenId].seller, "The seller can not buy it");
        require(Items[_tokenId].paymentType == PaymentType(1), "This item is not for USD sale");

        if (_USDPaymentType == USDPaymentType(0)) {
            bool sent1 = USDCAddress.transferFrom(msg.sender, address(this), (Items[_tokenId].price * marketplaceFee) / 100);
            bool sent2 = USDCAddress.transferFrom(msg.sender, Items[_tokenId].seller, (Items[_tokenId].price * (100 - marketplaceFee)) / 100);
            require(sent1, "Failed to transfer to contract");
            require(sent2, "Failed to transfer to user");
        } else {
            bool sent1 = USDTAddress.transferFrom(msg.sender, address(this), (Items[_tokenId].price * marketplaceFee) / 100);
            bool sent2 = USDTAddress.transferFrom(msg.sender, Items[_tokenId].seller, (Items[_tokenId].price * (100 - marketplaceFee)) / 100);
            require(sent1, "Failed to transfer to contract");
            require(sent2, "Failed to transfer to user");
        }
    
        uint256 priceEmit = Items[_tokenId].price;

        Items[_tokenId].price = 0;

        _itemsSolds.increment();

        emit itemSold(_tokenId, priceEmit, Items[_tokenId].seller, msg.sender, PaymentType(1));
    
    }

    event unsaledItem(uint256 tokenId, address seller);

    function unsaleItem(uint256 _tokenId) 
        payable 
        external {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
		require(ownerOf(_tokenId) == address(this), "NFT nos for sale");
        require(msg.sender == Items[_tokenId].seller, "Only the seller can unsale it");

        Items[_tokenId].price = 0;

        _transfer(address(this), msg.sender, _tokenId);
        
        emit unsaledItem(_tokenId, msg.sender);
    }

    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawERC20(address _to, uint256 amount, address _contractAddress) public onlyOwner {
        IERC20 contractAddress = IERC20(_contractAddress);
        bool sent = contractAddress.transferFrom(address(this), _to, amount);
        require(sent, "Failed to send ERC20");
    }
}
