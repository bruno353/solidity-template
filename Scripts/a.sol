// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Updated to more recent Solidity version

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

/**
 * @title IQueenNFT
 * @dev Interface for the Queen NFT contract
 */
interface IQueenNFT {
    function auctionMint(uint256 id, address to) external;
}

/**
 * @title QueenAuction
 * @dev Contract for auctioning Queen NFTs
 */
contract QueenAuction is Ownable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    // Auction configuration
    uint256 public bidIncrement;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minPrice;
    uint256 public auctionInterval = 8 hours; // Auction interval - 8 hours
    uint256 public constant TOTAL_AUCTION_ITEMS = 20;

    // Contract references
    IERC20 public daiToken;
    IQueenNFT public queenNft;

    // Events
    event Bid(uint256 indexed id, address indexed bidder, uint256 bid);
    event NFTClaim(uint256 indexed id, address indexed recipient, uint256 amount);
    event AuctionStarted(uint256 startTime, uint256 endTime);
    event AuctionIntervalUpdated(uint256 newInterval);
    event NFTContractUpdated(address newContract);

    /**
     * @dev Struct containing data about the highest bid for a particular NFT
     */
    struct AuctionData {
        uint256 id;
        uint256 highestBid;
        address highestBidder;
        bool isWithdrawn;
    }

    // Mapping from token id to AuctionData
    mapping(uint256 => AuctionData) public highestBidDetails;

    /**
     * @dev Constructor initializes the auction with required parameters
     * @param _bidIncrement The minimum increment between bids
     * @param _initialBid The minimum starting bid price
     * @param _queenAddress The address of the Queen NFT contract
     * @param _dai The address of the DAI token contract
     */
    constructor(
        uint256 _bidIncrement,
        uint256 _initialBid,
        address _queenAddress,
        address _dai
    ) {
        require(_bidIncrement > 0, "Bid increment must be greater than 0");
        require(_initialBid > 0, "Initial bid must be greater than 0");
        require(_queenAddress != address(0), "Queen NFT address cannot be zero");
        require(_dai != address(0), "DAI token address cannot be zero");

        bidIncrement = _bidIncrement;
        minPrice = _initialBid;
        queenNft = IQueenNFT(_queenAddress);
        daiToken = IERC20(_dai);
        
        __ReentrancyGuard_init(); // Initialize reentrancy guard
    }

    /**
     * @dev Returns the token id of the NFT currently up for auction
     * @return The active auction ID, or 0 if no auction is active
     */
    function getActiveID() public view returns (uint256) {
        if (startTime == 0 || block.timestamp <= startTime) {
            return 0;
        }
        
        uint256 timeDifference = block.timestamp - startTime;
        uint256 id = timeDifference / auctionInterval;

        if (id >= TOTAL_AUCTION_ITEMS) {
            return 0;
        }

        return TOTAL_AUCTION_ITEMS - id;
    }

    /**
     * @dev Place a bid for the current NFT up for auction
     * @param id The ID of the NFT being bid on
     * @param amount The bid amount in DAI tokens
     * @return success True if the bid was successful
     */
    function placeBid(uint256 id, uint256 amount)
        public
        nonReentrant
        onlyAfterStart
        onlyBeforeEnd
        shouldBeAuctionID(id)
        shouldBeActiveID(id)
        returns (bool success)
    {
        require(daiToken.balanceOf(msg.sender) >= amount, "Insufficient balance to place bid");
        require(amount >= minPrice, "Amount is lower than base price");
        require((amount - minPrice) % bidIncrement == 0, "Increment should be a multiple of bidIncrement");
        
        AuctionData memory currentBidData = highestBidDetails[id];

        if (currentBidData.highestBid > 0) {
            require(
                amount >= (currentBidData.highestBid + bidIncrement),
                "New bid must be increased by at least the bid increment"
            );
        }

        // Store the previous bidder details for refund
        address previousBidder = currentBidData.highestBidder;
        uint256 previousBid = currentBidData.highestBid;

        // Update highest bid data
        currentBidData.highestBid = amount;
        currentBidData.highestBidder = msg.sender;
        currentBidData.id = id;
        highestBidDetails[id] = currentBidData;

        // Transfer tokens from bidder to contract
        daiToken.safeTransferFrom(msg.sender, address(this), amount);

        // Refund previous bidder if exists
        if (previousBid > 0 && previousBidder != address(0)) {
            daiToken.safeTransfer(previousBidder, previousBid);
        }

        emit Bid(id, msg.sender, amount);
        return true;
    }

    /**
     * @dev Mints an NFT for the winner of the auction
     * @param id The ID of the NFT to claim
     * @return success True if the claim was successful
     */
    function claimNFT(uint256 id)
        public
        nonReentrant
        shouldBeAuctionID(id)
        onlyEnded(id)
        onlyOwner
        returns (bool success)
    {
        AuctionData storage data = highestBidDetails[id];
        
        require(data.highestBid > 0, "No valid bids for this NFT");
        require(!data.isWithdrawn, "NFT already claimed");
        require(data.highestBidder != address(0), "Invalid winning address");

        data.isWithdrawn = true;

        // Mint NFT to the highest bidder
        queenNft.auctionMint(id, data.highestBidder);

        emit NFTClaim(id, data.highestBidder, data.highestBid);
        return true;
    }

    /**
     * @dev Returns the highest bidder data for a specific NFT
     * @param id The ID of the NFT
     * @return The auction data for the specified NFT
     */
    function getHighestBidder(uint256 id) public view returns (AuctionData memory) {
        require(id >= 1 && id <= TOTAL_AUCTION_ITEMS, "Invalid NFT ID");
        return highestBidDetails[id];
    }

    /**
     * @dev Changes the auction interval
     * @param _interval The new auction interval in seconds
     */
    function setAuctionInterval(uint256 _interval) public onlyOwner {
        require(_interval > 0, "Interval must be greater than 0");
        auctionInterval = _interval;
        emit AuctionIntervalUpdated(_interval);
    }

    /**
     * @dev Changes the NFT contract address
     * @param _addr The new NFT contract address
     */
    function changeNFTInterface(address _addr) public onlyOwner {
        require(_addr != address(0), "NFT address cannot be zero");
        queenNft = IQueenNFT(_addr);
        emit NFTContractUpdated(_addr);
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract to the owner
     * @param _tokenAddress The address of the ERC20 token to withdraw
     */
    function withdrawTokens(address _tokenAddress) public onlyOwner onlyAfterEnd {
        require(_tokenAddress != address(0), "Invalid token address");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        
        require(balance > 0, "No tokens to withdraw");
        
        token.safeTransfer(owner(), balance);
    }

    /**
     * @dev Starts the auction
     */
    function startAuction() public onlyOwner {
        require(startTime == 0, "Auction already started");

        startTime = block.timestamp;
        endTime = startTime + (TOTAL_AUCTION_ITEMS * auctionInterval);
        
        emit AuctionStarted(startTime, endTime);
    }

    /**
     * @dev Requires the ID to be of a token that has finished being auctioned
     */
    modifier onlyEnded(uint256 id) {
        require(id > getActiveID(), "Auction not ended for the given ID");
        _;
    }

    /**
     * @dev Requires the ID to be the ID of the active NFT for auction
     */
    modifier shouldBeActiveID(uint256 id) {
        require(id == getActiveID(), "Not an active ID");
        _;
    }

    /**
     * @dev Requires that the auction ID is a valid token for auction
     */
    modifier shouldBeAuctionID(uint256 id) {
        require(id >= 1 && id <= TOTAL_AUCTION_ITEMS, "Invalid ID");
        _;
    }

    /**
     * @dev Requires that the auction has started
     */
    modifier onlyAfterStart() {
        require(startTime > 0, "Auction hasn't started");
        require(block.timestamp > startTime, "Auction not started yet");
        _;
    }

    /**
     * @dev Requires that the auction has not ended
     */
    modifier onlyBeforeEnd() {
        require(endTime > 0, "End time not set");
        require(block.timestamp < endTime, "Auction ended");
        _;
    }

    /**
     * @dev Requires that the auction has ended
     */
    modifier onlyAfterEnd() {
        require(endTime > 0, "End time not set");
        require(block.timestamp > endTime, "Auction not over");
        _;
    }
}