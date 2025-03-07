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

/**
 * @title gantier
 * @notice nft marketplace contract with minting, buying and selling features
 * @dev inherits from erc721uristorage, ownable and reentrancyguard
 */
contract Gantier is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // counters for token ids, items sold and nfts minted by owner
    Counters.Counter public tokenIds;
    Counters.Counter public itemsSold;
    Counters.Counter public nftsMintedByOwner;

    uint256 public maxSupply = 3333;
    uint256 public marketplaceFee = 3; // 3% fee (base 100)

    // flag to enable or disable contract functionality
    bool public isEnabled = true;

    // erc20 token interfaces for usdc and usdt (assumed 6 decimals)
    IERC20 public usdcToken;
    IERC20 public usdtToken;

    /**
     * @dev enum representing the type of payment accepted
     */
    enum PaymentType {
        Matic,
        USD
    }

    // mapping for tracking nfts minted per wallet for each token id
    mapping(uint256 => mapping(address => uint256)) public nftsMintedPerWallet;
    
    // mapping to store nft character uris
    mapping(uint256 => string) public nftCharacterToURI;

    /**
     * @dev struct representing an item in the marketplace
     */
    struct Item {
        uint256 id;
        uint256 price;
        address seller;
        PaymentType paymentType;
    }
    
    // mapping from token id to marketplace item
    mapping(uint256 => Item) public items;

    /**
     * @notice constructor
     * @param _usdcAddress address of the usdc token contract
     * @param _usdtAddress address of the usdt token contract
     * @param _marketplaceFee initial marketplace fee (base 100)
     */
    constructor (
        address _usdcAddress,
        address _usdtAddress,
        uint256 _marketplaceFee
    )
        Ownable()
        ERC721("Gantier", "GA")
    {
        usdcToken = IERC20(_usdcAddress);
        usdtToken = IERC20(_usdtAddress);
        marketplaceFee = _marketplaceFee;
    }
    
    /**
     * @notice sets the usdc and usdt token contract addresses
     * @param _usdcAddress new usdc token address
     * @param _usdtAddress new usdt token address
     */
    function setTokensAddress(address _usdcAddress, address _usdtAddress) public onlyOwner {
        usdcToken = IERC20(_usdcAddress);
        usdtToken = IERC20(_usdtAddress);
    }

    /**
     * @notice mints new nfts with given uris to a specified address
     * @param _uris array of token uris for the new nfts
     * @param _to address to receive the minted nfts
     */
    function mintNFT(string[] memory _uris, address _to) public onlyOwner {
        require(isEnabled, "contract is not enabled");
    
        for (uint256 i = 0; i < _uris.length; i++) {
            tokenIds.increment();
            uint256 newTokenId = tokenIds.current();

            _safeMint(_to, newTokenId);
            _setTokenURI(newTokenId, _uris[i]);

            items[newTokenId] = Item({
                id: newTokenId,
                price: 0,
                seller: _to,
                paymentType: PaymentType.Matic
            });
        }
    }

    /**
     * @notice enables or disables the contract functionality
     * @param _enabled new state of the contract
     */
    function setContractEnabled(bool _enabled) public onlyOwner {
        isEnabled = _enabled;
    }

    /**
     * @notice updates the uris for multiple nfts
     * @param _nftIds array of token ids
     * @param _nftURIs array of new uris corresponding to the token ids
     */
    function setURIs(uint256[] memory _nftIds, string[] memory _nftURIs) public onlyOwner {
        require(_nftIds.length == _nftURIs.length, "arrays must be equal length");
        for (uint256 i = 0; i < _nftIds.length; i++) { 
            _setTokenURI(_nftIds[i], _nftURIs[i]);
        }
    }

    /**
     * @notice transfers an nft from one address to another
     * @param _tokenId token id to transfer
     * @param _from address to transfer from
     * @param _to address to transfer to
     */
    function transferNFTOwner(uint256 _tokenId, address _from, address _to) public onlyOwner {
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @notice burns (destroys) an nft
     * @param _tokenId token id to burn
     */
    function burnNFTOwner(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

    // ========================
    // marketplace functions
    // ========================

    /**
     * @notice emitted when an nft is listed for sale
     */
    event ItemAddedForSale(uint256 indexed id, uint256 price, address seller);

    /**
     * @notice emitted when an nft is sold
     */
    event ItemSold(uint256 indexed id, uint256 price, address seller, address buyer, PaymentType paymentType);  

    /**
     * @notice lists an nft for sale in the marketplace
     * @param _tokenId token id to list
     * @param _price price of the token
     * @param _paymentType type of payment accepted (matic or usd)
     */
    function putItemForSale(uint256 _tokenId, uint256 _price, PaymentType _paymentType) public {
        require(ownerOf(_tokenId) == msg.sender, "not token owner");
        require(_price > 0, "price must be greater than 0");

        items[_tokenId].price = _price;
        items[_tokenId].seller = msg.sender;
        items[_tokenId].paymentType = _paymentType;

        _transfer(msg.sender, address(this), _tokenId);

        emit ItemAddedForSale(_tokenId, _price, msg.sender);
    }

    /**
     * @notice lists an nft for sale on behalf of the seller by the contract owner
     * @param _tokenId token id to list
     * @param _price price of the token
     * @param seller address of the seller
     * @param _paymentType type of payment accepted (matic or usd)
     */
    function putItemForSaleOwner(uint256 _tokenId, uint256 _price, address seller, PaymentType _paymentType) public onlyOwner {
        require(_price > 0, "price must be greater than 0");

        items[_tokenId].price = _price;
        items[_tokenId].seller = seller;
        items[_tokenId].paymentType = _paymentType;

        _transfer(seller, address(this), _tokenId);

        emit ItemAddedForSale(_tokenId, _price, seller);
    }

    /**
     * @notice buys an nft using matic
     * @param _tokenId token id to buy
     */
    function buyItemWithMatic(uint256 _tokenId) external payable nonReentrant {
        require(tokenIds.current() >= _tokenId, "nft does not exist");
        require(ownerOf(_tokenId) == address(this), "token not for sale");
        require(msg.value >= items[_tokenId].price, "insufficient funds sent");
        require(msg.sender != items[_tokenId].seller, "seller cannot buy own token");
        require(items[_tokenId].paymentType == PaymentType.Matic, "item not for matic sale");
    
        uint256 price = items[_tokenId].price;
        // reset item listing details
        items[_tokenId].price = 0;
        address seller = items[_tokenId].seller;
        items[_tokenId].seller = msg.sender;
        
        // transfer 97% of funds to seller (3% fee retained by marketplace)
        payable(seller).transfer((msg.value * 97) / 100);

        itemsSold.increment();
        
        _transfer(address(this), msg.sender, _tokenId);

        emit ItemSold(_tokenId, price, seller, msg.sender, PaymentType.Matic);
    }

    /**
     * @dev enum for usd payment types
     */
    enum USDPaymentType {
        USDC,
        USDT
    }

    /**
     * @notice buys an nft using usd (usdc or usdt)
     * @param _tokenId token id to buy
     * @param _usdPaymentType type of usd payment (usdc or usdt)
     */
    function buyItemWithUSD(uint256 _tokenId, USDPaymentType _usdPaymentType) external nonReentrant {
        require(tokenIds.current() >= _tokenId, "nft does not exist");
        require(ownerOf(_tokenId) == address(this), "token not for sale");
        require(msg.sender != items[_tokenId].seller, "seller cannot buy own token");
        require(items[_tokenId].paymentType == PaymentType.USD, "item not for usd sale");

        uint256 price = items[_tokenId].price;

        if (_usdPaymentType == USDPaymentType.USDC) {
            bool sentContract = usdcToken.transferFrom(msg.sender, address(this), (price * marketplaceFee) / 100);
            bool sentSeller = usdcToken.transferFrom(msg.sender, items[_tokenId].seller, (price * (100 - marketplaceFee)) / 100);
            require(sentContract, "failed to transfer usdc to contract");
            require(sentSeller, "failed to transfer usdc to seller");
        } else {
            bool sentContract = usdtToken.transferFrom(msg.sender, address(this), (price * marketplaceFee) / 100);
            bool sentSeller = usdtToken.transferFrom(msg.sender, items[_tokenId].seller, (price * (100 - marketplaceFee)) / 100);
            require(sentContract, "failed to transfer usdt to contract");
            require(sentSeller, "failed to transfer usdt to seller");
        }
    
        // reset item listing details
        items[_tokenId].price = 0;
        address seller = items[_tokenId].seller;
        items[_tokenId].seller = msg.sender;

        _transfer(address(this), msg.sender, _tokenId);

        itemsSold.increment();

        emit ItemSold(_tokenId, price, seller, msg.sender, PaymentType.USD);
    }

    /**
     * @notice emitted when an item is removed from sale
     */
    event ItemUnlisted(uint256 tokenId, address seller);

    /**
     * @notice removes an nft from sale
     * @param _tokenId token id to remove from sale
     */
    function unsaleItem(uint256 _tokenId) external {
        require(tokenIds.current() >= _tokenId, "nft does not exist");
        require(ownerOf(_tokenId) == address(this), "nft not for sale");
        require(msg.sender == items[_tokenId].seller, "only seller can unsale");

        items[_tokenId].price = 0;
        _transfer(address(this), msg.sender, _tokenId);
        
        emit ItemUnlisted(_tokenId, msg.sender);
    }

    /**
     * @notice withdraws ether from the contract
     * @param _to address to send ether
     * @param _amount amount of ether to withdraw
     */
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "failed to send ether");
    }

    /**
     * @notice withdraws erc20 tokens from the contract
     * @param _to address to send tokens
     * @param amount amount of tokens to withdraw
     * @param _contractAddress address of the erc20 token contract
     */
    function withdrawERC20(address _to, uint256 amount, address _contractAddress) public onlyOwner {
        IERC20 tokenContract = IERC20(_contractAddress);
        bool sent = tokenContract.transfer(_to, amount);
        require(sent, "failed to send erc20");
    }

    // ========================
    // purchase order functions
    // ========================

    /**
     * @dev struct representing a purchase order
     */
    struct PurchaseOrder {
        address buyer;
        uint256 amount;
        bool isUSDC;
        bool processed;
    }

    // mapping from order id to purchase order details
    mapping(uint256 => PurchaseOrder) public purchaseOrders;
    Counters.Counter private purchaseOrderIds;

    /**
     * @notice emitted when a purchase order is created
     */
    event PurchaseOrderCreated(uint256 orderId, address buyer, uint256 amount, bool isUSDC);

    /**
     * @notice emitted when a purchase order is processed
     */
    event PurchaseOrderProcessed(uint256 orderId, uint256 tokenId);

    /**
     * @notice creates a new purchase order
     * @param _amount amount of tokens to pay
     * @param _isUSDC true if paying with usdc, false for usdt
     */
    function createPurchaseOrder(uint256 _amount, bool _isUSDC) external nonReentrant {
        require(_amount > 0, "amount must be greater than 0");

        IERC20 token = _isUSDC ? usdcToken : usdtToken;
        require(token.transferFrom(msg.sender, address(this), _amount), "token transfer failed");

        purchaseOrderIds.increment();
        uint256 newOrderId = purchaseOrderIds.current();

        purchaseOrders[newOrderId] = PurchaseOrder({
            buyer: msg.sender,
            amount: _amount,
            isUSDC: _isUSDC,
            processed: false
        });

        emit PurchaseOrderCreated(newOrderId, msg.sender, _amount, _isUSDC);
    }

    /**
     * @notice processes a purchase order and mints an nft
     * @param _orderId order id to process
     * @param _tokenURI uri for the minted nft
     */
    function processPurchaseOrder(uint256 _orderId, string memory _tokenURI) external onlyOwner {
        require(_orderId <= purchaseOrderIds.current(), "invalid order id");
        PurchaseOrder storage order = purchaseOrders[_orderId];
        require(!order.processed, "order already processed");

        tokenIds.increment();
        uint256 newTokenId = tokenIds.current();

        _safeMint(order.buyer, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        order.processed = true;

        emit PurchaseOrderProcessed(_orderId, newTokenId);
    }

    /**
     * @notice refunds a purchase order
     * @param _orderId order id to refund
     */
    function refundPurchaseOrder(uint256 _orderId) external onlyOwner {
        require(_orderId <= purchaseOrderIds.current(), "invalid order id");
        PurchaseOrder storage order = purchaseOrders[_orderId];
        require(!order.processed, "order already processed");

        IERC20 token = order.isUSDC ? usdcToken : usdtToken;
        require(token.transfer(order.buyer, order.amount), "refund failed");

        order.processed = true;
    }
}
