// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IQueenNFT {
    function auctionMint(uint id, address to) external;
}


contract QueenAuction is Ownable {

    using SafeERC20 for IERC20;

    uint public bidIncrement;
    uint public startTime;
    uint public endTime;

    IERC20 public daiToken;

    IQueenNFT public queenNft;

    uint public minPrice;

    uint auctionInterval = 8 hours; // Auction interval - 8 hours

    //Events for Bidding and claiming NFT
    event Bid(uint id, address bidder, uint bid);

    //Event emitted when the winer has claimed their nft
    event NFTClaim(uint id, address withdrawalAccount, uint amount);

    constructor (uint _bidIncrement, uint _initialBid, address _queenAddress, address _dai) {
       
        bidIncrement = _bidIncrement;
        minPrice = _initialBid;
        queenNft = IQueenNFT(_queenAddress);
        daiToken = IERC20(_dai);

    }

    ///Struct containing data about the highest bid for a particular nft
    struct AuctionData {
        uint id;
        uint highestBid;
        address highestBidder;
        bool isWithdrawn;
    }

    //mapping from token id to auctionData
    mapping(uint => AuctionData) public HighestBidDetails;

    
    /**
    * @dev Returns the token id of the nft currently up for auction, returns 0 if there is nothing up for auction
    */
    function getActiveID() public view returns(uint) {
        uint timeDifference = block.timestamp - startTime;
        uint id = timeDifference / auctionInterval;

        if(id >= 20) {
            return 0;
        }

        unchecked {
            return 20 - id;
        }
    }

    /**
    * @dev Place a bid for the current nft up for auction
    * requires the auction to have started and not be over, the nft being bid on to be the current nft for auction,
    * and the value of the bid to be at least the minimum bid amount, greator than the current highest bid, and increased from the min bid
    * by a multiple of bidIncrement.
    * @notice dai tokens are sent to the contract on successful bid, and if a bid is beaten the tokens they sent will be sent back
    */
    function placeBid(uint id, uint amount)
        public
        onlyAfterStart
        onlyBeforeEnd
        shouldBeAuctionID(id)
        shouldBeActiveID(id)
        returns (bool success)
    {
    
        require(daiToken.balanceOf(msg.sender) >= amount, "Insufficient balance to place bid");
        
        AuctionData memory highestBidder = HighestBidDetails[id];

        require(amount >= minPrice, "Amount is lower than base price");

        require((amount - minPrice) % bidIncrement == 0, "Increment should be a multiple of bidIncrement");
        
        if(highestBidder.highestBid > 0) {

            require(amount >= (highestBidder.highestBid + bidIncrement), "New Bid must be increased by the bid increment");
        }

        // Transfer tokens to this contract
        daiToken.transferFrom(msg.sender, address(this), amount);

        // If there was a previous bidder, send the tokens back
        if(highestBidder.highestBid > 0) {
            daiToken.transfer(highestBidder.highestBidder, highestBidder.highestBid);
        }

        highestBidder.highestBid = amount;
        highestBidder.highestBidder = msg.sender;
        highestBidder.id = id;

        HighestBidDetails[id] = highestBidder;

        emit Bid(id, highestBidder.highestBidder, highestBidder.highestBid);
        return true;
    }

    /**
    * @dev Mints a nft for the winner of the auction for that nft
    * Requires the nft to not have been already claimed, and that the auction for that nft to be over
    */
    function claimNFT(uint id)
        shouldBeAuctionID(id)
        onlyEnded(id)
        onlyOwner
        public
        returns (bool success)
    {
        require(!HighestBidDetails[id].isWithdrawn, "Already withdrawn");

        AuctionData memory data = HighestBidDetails[id];
        require(data.highestBid > 0, "None of the Bid has enough wallet balance");

        address withdrawalAccount = data.highestBidder;
        uint withdrawalAmount = data.highestBid;
        data.isWithdrawn = true;

        require(withdrawalAccount != address(0) && withdrawalAmount > 0, "Unable to withdraw");

        queenNft.auctionMint(id, withdrawalAccount);
        HighestBidDetails[id] = data;

        emit NFTClaim(id, withdrawalAccount, withdrawalAmount);

        return true;
    }

    function getHighestBidder(uint id) public view returns(AuctionData memory) {

        return HighestBidDetails[id];

    }

    /**
    * @dev Changes the auction interval
    * Requires the caller to be the owner of this contract
    */
    function setAuctionInterval(uint _interval) public onlyOwner {
        auctionInterval = _interval;
    }

    /**
    * @dev Changes the nft that will be minted on claiming a successful bid for a token
    */
    function changeNFTinterface(address _addr) public onlyOwner {
        queenNft = IQueenNFT(_addr);
    }

    /**
    * @dev Withdraws erc20 tokens of the provided address from the contract to the owner of the contract
    * Requires the caller to be the owner of this contract, and can only be called once all the auctions have been completed
    */
	function withdrawTokens(address _tokenAddress) public onlyOwner onlyAfterEnd {
		require(_tokenAddress != address(0), "invalid address");

        IERC20 token = IERC20(_tokenAddress);

		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

    /**
    * @dev starts the auction, setting the start time as the current time, and the end time as 20 * the auction interval
    * Requires the caller to be the owner of this contract
    */
    function startAuction() public onlyOwner {

        uint time = block.timestamp;

        startTime = time;

        endTime = time + (20 * auctionInterval);

    }

    /**
    * @dev requires the id to be of a token that has finished being auctioned
    */
    modifier onlyEnded(uint id) {
        require(id > getActiveID(), "Auction not ended for the given ID");
        _;
    }

    /**
    * @dev requires the id to be the id of the active nft for auction
    */
    modifier shouldBeActiveID(uint id) {
        require(id == getActiveID(), "Not an active ID");
        _;
    }

    /**
    * @dev requires that the auction id is a valid token for auction
    */
    modifier shouldBeAuctionID(uint id) {
        require(id >= 1 && id <= 20, "Invalid ID");
        _;
    }

    /**
    * @dev requires that the auction has started
    */
    modifier onlyAfterStart {
        require(startTime > 0, "Auction hasnt started");
        require(block.timestamp > startTime, "Auction not started yet!");
        _;
    }

    /**
    * @dev requires that the auction has has not ended
    */
    modifier onlyBeforeEnd {
        require(endTime > 0, "Endtime not set");
        require(block.timestamp < endTime, "Auction ended!");
        _;
    }

    /**
    * @dev requires that the auction has has ended
    */
    modifier onlyAfterEnd {
        require(endTime > 0, "EndTime not set");
        require(block.timestamp > endTime, "Auction not over");
        _;
    }

}
