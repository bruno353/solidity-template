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

/// @title Gantier NFT Marketplace Contract
/// @notice This contract implements an NFT marketplace with various features including minting, buying, and selling NFTs
/// @dev Inherits from ERC721URIStorage, Ownable, and ReentrancyGuard
contract Gantier is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Counters for tracking token IDs, sold items, and NFTs minted by owner
    Counters.Counter public _tokenIds;
    Counters.Counter public _itemsSolds;
    Counters.Counter public _NFTsMintedByOwner;

    uint256 public maxSupply = 3333;
    uint256 public marketplaceFee = 3;  // 3% fee (base 100)

    // Flag to enable/disable contract functionality
    bool public isEnabled = true;

    // ERC20 token addresses for USDC and USDT (both with 6 decimals)
    IERC20 public USDCAddress;
    IERC20 public USDTAddress;

    // Enum to represent payment types in the marketplace
    enum PaymentType {
        Matic,
        USD
    }

    // Mapping to track NFTs minted per wallet for each token ID
    mapping(uint256 => mapping(address => uint256)) public nftsMintedPerWallet;
    
    // Mapping to store NFT character URIs
    mapping(uint256 => string) public NFTCharacterToURI;

    // Struct to represent an item in the marketplace
    struct Item {
        uint256 id;
        uint256 price;
        address seller;
        PaymentType paymentType;
    }
    
    // Mapping to store marketplace items
    mapping(uint256 => Item) public Items; //id => Item

    /// @notice Contract constructor
    /// @param _USDCAddress Address of the USDC token contract
    /// @param _USDTAddress Address of the USDT token contract
    /// @param _marketplaceFee Initial marketplace fee (base 100)
    constructor (address _USDCAddress, address _USDTAddress, uint256 _marketplaceFee) Ownable(msg.sender) ERC721("Gantier", "GA")  {
        USDCAddress = IERC20(_USDCAddress);
        USDTAddress = IERC20(_USDTAddress);
        marketplaceFee = _marketplaceFee;
    }
    
    /// @notice Sets the addresses for USDC and USDT tokens
    /// @param _USDCAddress New address for USDC token
    /// @param _USDTAddress New address for USDT token
    function setTokensAddress(address _USDCAddress, address _USDTAddress) public onlyOwner {
        USDCAddress = IERC20(_USDCAddress);
        USDTAddress = IERC20(_USDTAddress);
    }

    // Event emitted when an NFT is minted
    event NFTMinted (uint256 id, string uri, address minter);

    /// @notice Mints new NFTs and assigns them to a specified address
    /// @param _uris Array of token URIs for the new NFTs
    /// @param _to Address to receive the minted NFTs
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

    /// @notice Enables or disables the contract functionality
    /// @param _bool New state for the contract
    function setContractEnabled(bool _bool) public onlyOwner {
        isEnabled = _bool;
    }

    /// @notice Updates the URIs for multiple NFTs
    /// @param _nftsArray Array of token IDs to update
    /// @param _nftsURIs Array of new URIs corresponding to the token IDs
    function setURIs( uint256[] memory _nftsArray, string[] memory _nftsURIs) public onlyOwner {
        for (uint i = 0; i < _nftsArray.length; i++) { 
            _setTokenURI(_nftsArray[i], _nftsURIs[i]);
        }
    }

    /// @notice Allows the owner to transfer NFTs between addresses
    /// @param _tokenId ID of the token to transfer
    /// @param _from Address to transfer from
    /// @param _to Address to transfer to
    function transferNFTOwner(uint256 _tokenId, address _from, address _to)
        public 
        onlyOwner {
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Allows the owner to burn (destroy) an NFT
    /// @param _tokenId ID of the token to burn
    function burnNFTOwner(uint256 _tokenId)
        public 
        onlyOwner {
        _burn(_tokenId);
    }

    // MARKETPLACE FUNCTIONS

    // Event emitted when an item is listed for sale
    event itemAddedForSale(uint256 id, uint256 price, address seller);
    // Event emitted when an item is sold
    event itemSold(uint256 id, uint256 price, address seller, address buyer, PaymentType _paymentType);  

    /// @notice Lists an NFT for sale in the marketplace
    /// @param _tokenId ID of the token to list
    /// @param _price Price of the token
    /// @param _paymentType Type of payment accepted (Matic or USD)
    function putItemForSale(uint256 _tokenId, uint256 _price, PaymentType _paymentType)
        public 
        {
        require(ownerOf(_tokenId) == msg.sender, "You are not the token owner");
        require(_price > 0 , "Price needs to be greater than 0");

        Items[_tokenId].price = _price;
        Items[_tokenId].seller = msg.sender;
        Items[_tokenId].paymentType = _paymentType;

        _transfer(msg.sender, address(this), _tokenId);

        emit itemAddedForSale(_tokenId, _price, msg.sender);
    }

    /// @notice Allows the owner to list an NFT for sale
    /// @param _tokenId ID of the token to list
    /// @param _price Price of the token
    /// @param seller Address of the seller
    /// @param _paymentType Type of payment accepted (Matic or USD)
    function putItemForSaleOwner(uint256 _tokenId, uint256 _price, address seller, PaymentType _paymentType)
        public 
        onlyOwner {
        require(_price > 0 , "Price needs to be greater than 0");

        Items[_tokenId].price = _price;
        Items[_tokenId].seller = seller;
        Items[_tokenId].paymentType = _paymentType;

        _transfer(seller, address(this), _tokenId);

        emit itemAddedForSale(_tokenId, _price, seller);
    }

    /// @notice Allows a user to buy an NFT listed for sale using Matic
    /// @param _tokenId ID of the token to buy
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
        Items[_tokenId].seller = msg.sender;
        
        // Transfer 97% to seller (3% fee)
        payable(Items[_tokenId].seller).transfer((msg.value * 97) / 100);

        _itemsSolds.increment();
        
        _transfer(address(this), msg.sender, _tokenId);

        emit itemSold(_tokenId, priceEmit, Items[_tokenId].seller, msg.sender, PaymentType(0));
    }

    // Enum to represent USD payment types
    enum USDPaymentType {
        USDC,
        USDT
    }

    /// @notice Allows a user to buy an NFT listed for sale using USD (USDC or USDT)
    /// @param _tokenId ID of the token to buy
    /// @param _USDPaymentType Type of USD payment (USDC or USDT)
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
        Items[_tokenId].seller = msg.sender;

        _transfer(address(this), msg.sender, _tokenId);

        _itemsSolds.increment();

        emit itemSold(_tokenId, priceEmit, Items[_tokenId].seller, msg.sender, PaymentType(1));
    }

    // Event emitted when an item is removed from sale
    event unsaledItem(uint256 tokenId, address seller);

    /// @notice Allows a seller to remove their NFT from sale
    /// @param _tokenId ID of the token to remove from sale
    function unsaleItem(uint256 _tokenId) 
        payable 
        external {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
        require(ownerOf(_tokenId) == address(this), "NFT not for sale");
        require(msg.sender == Items[_tokenId].seller, "Only the seller can unsale it");

        Items[_tokenId].price = 0;

        _transfer(address(this), msg.sender, _tokenId);
        
        emit unsaledItem(_tokenId, msg.sender);
    }

    /// @notice Allows the owner to withdraw Ether from the contract
    /// @param _to Address to send the Ether to
    /// @param _amount Amount of Ether to withdraw
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice Allows the owner to withdraw ERC20 tokens from the contract
    /// @param _to Address to send the tokens to
    /// @param amount Amount of tokens to withdraw
    /// @param _contractAddress Address of the ERC20 token contract
    function withdrawERC20(address _to, uint256 amount, address _contractAddress) public onlyOwner {
        IERC20 contractAddress = IERC20(_contractAddress);
        bool sent = contractAddress.transfer(_to, amount);
        require(sent, "Failed to send ERC20");
    }

    // Struct to represent a purchase order
    struct PurchaseOrder {
        address buyer;
        uint256 amount;
        bool isUSDC;
        bool processed;
    }

    // Mapping to store purchase orders
    mapping(uint256 => PurchaseOrder) public purchaseOrders;
    Counters.Counter private _purchaseOrderIds;

    // Event emitted when a purchase order is created
    event PurchaseOrderCreated(uint256 orderId, address buyer, uint256 amount, bool isUSDC);

    // Event emitted when a purchase order is processed
    event PurchaseOrderProcessed(uint256 orderId, uint256 tokenId);

    /// @notice Creates a new purchase order
    /// @param _amount Amount of tokens to pay
    /// @param _isUSDC True if paying with USDC, false for USDT
    function createPurchaseOrder(uint256 _amount, bool _isUSDC) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");

        IERC20 token = _isUSDC ? USDCAddress : USDTAddress;
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        _purchaseOrderIds.increment();
        uint256 newOrderId = _purchaseOrderIds.current();

        purchaseOrders[newOrderId] = PurchaseOrder({
            buyer: msg.sender,
            amount: _amount,
            isUSDC: _isUSDC,
            processed: false
        });

        emit PurchaseOrderCreated(newOrderId, msg.sender, _amount, _isUSDC);
    }

    /// @notice Processes a purchase order and mints an NFT
    /// @param _orderId ID of the purchase order to process
    /// @param _tokenURI URI for the new NFT
    function processPurchaseOrder(uint256 _orderId, string memory _tokenURI) external onlyOwner {
        require(_orderId <= _purchaseOrderIds.current(), "Invalid order ID");
        PurchaseOrder storage order = purchaseOrders[_orderId];
        require(!order.processed, "Order already processed");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(order.buyer, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        order.processed = true;

        emit PurchaseOrderProcessed(_orderId, newTokenId);
    }

    /// @notice Refunds a purchase order
    /// @param _orderId ID of the purchase order to refund
    function refundPurchaseOrder(uint256 _orderId) external onlyOwner {
        require(_orderId <= _purchaseOrderIds.current(), "Invalid order ID");
        PurchaseOrder storage order = purchaseOrders[_orderId];
        require(!order.processed, "Order already processed");

        IERC20 token = order.isUSDC ? USDCAddress : USDTAddress;
        require(token.transfer(order.buyer, order.amount), "Refund failed");

        order.processed = true;
    }
}
