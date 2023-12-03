//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArcadeWheel is RrpRequesterV0, ReentrancyGuard {

    using Counters for Counters.Counter;

    //events for the random number getter:
    event RequestedUint256(bytes32 indexed requestId);

 
    //emit when the user earns a reward
    //reward subs: 0 => tryAgain; 1 => freeSpin; 2 => JackPot; 3 => 150 USDC; 4 => 50 USDC; 5 => 10 USDC; 6 => 5 USDC
    event RewardReceived(uint256 reward, address _address, bytes32 indexed requestId);

    //emit when the user claims his rewards:
    //reward claimed subs: 0 => freeSpin; 2 => HNY; 3 => USDC; 4 => all
    event RewardClaimed(uint256 reward, address user);

    // These can be set using setRequestParameters())
    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;

    address public owner;

    bool public contractEnabled;

    //tokens addresses
    IERC20 public HNYAddress;


    //setando a base decimal:
    uint256 _baseDecimal;

    //fee require to spin the wheel
    uint256 public fee = 5 * 10 ** _baseDecimal;

    //Each user will have its "wallet", so it can be stored the user rewards:
    struct user {
        uint256 HNY;
    }

    //mappings:
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(address => user) public addressToUser;
    mapping(bytes32 => address) public requestIdToAddress;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // function to enable/disable contract, in case of error or exploit:
    modifier onlyContractEnabled() {
        require(contractEnabled == true);
        _;
    }

    constructor(address _airnodeRrp, address _HNYAddress, uint256 baseDecimal) RrpRequesterV0(_airnodeRrp) {
        owner = msg.sender;
        contractEnabled = true;
        HNYAddress = IERC20(_HNYAddress);
        _baseDecimal = baseDecimal;
    }

    function setTokensAddress(address _HNYAddress) public onlyOwner() {
        HNYAddress = IERC20(_HNYAddress);
    }

    function setBaseDecimal(uint256 baseDecimal) public onlyOwner() {
        _baseDecimal = baseDecimal;
    }

    function setOwner(address _address) public onlyOwner() {
        owner = _address;
    }

    function setFee(uint256 _fee) public onlyOwner() {
        fee = _fee;
    }


    //spin the wheel
    function spinWheel() public  onlyContractEnabled() {
        bool sent = HNYAddress.transferFrom(msg.sender, address(this), fee);
        require(sent, "Failed to spin the wheel");

        makeRequestUint256();

    }


    //claiming USDC tokens:
    function claimHNY() public onlyContractEnabled() nonReentrant {
            require(addressToUser[msg.sender].HNY >= 1, "You dont have USDC available for claiming");
            uint256 HNYAmount = addressToUser[msg.sender].HNY;
            addressToUser[msg.sender].HNY = 0;
            bool sent = HNYAddress.transfer(msg.sender, HNYAmount * 10 ** _baseDecimal);
            require(sent, "Failed to withdraw the tokens");
            emit RewardClaimed(1, msg.sender);
    }


    // Set parameters used by airnodeRrp.makeFullRequest(...)
    // See makeRequestUint256()
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external {
        // Normally, this function should be protected, as in:
        // require(msg.sender == owner, "Sender not owner");
        require(msg.sender == owner);
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    // Calls the AirnodeRrp contract with a request
    // airnodeRrp.makeFullRequest() returns a requestId to hold onto.
    function makeRequestUint256() private {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
        );
        // Store the requestId
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        requestIdToAddress[requestId] = msg.sender;
        emit RequestedUint256(requestId);
    }



    // AirnodeRrp will call back with a response
    function fulfillUint256(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        // Verify the requestId exists
        require(
            expectingRequestWithIdToBeFulfilled[requestId],
            "Request ID not known"
        );

        
        expectingRequestWithIdToBeFulfilled[requestId] = false;
        uint256 qrngUint256 = abi.decode(data, (uint256));
        
        uint256 randomic = ((qrngUint256) % 2);

        if (randomic == 0){
            emit RewardReceived(0, requestIdToAddress[requestId], requestId);
        }

        if (randomic == 1){
            addressToUser[requestIdToAddress[requestId]].HNY = addressToUser[requestIdToAddress[requestId]].HNY + 10;
            emit RewardReceived(1, requestIdToAddress[requestId], requestId);
        }
    }

    function fundMe() public payable{
    }


    function returnUserWallet(address _address) public view returns(user memory){
        return addressToUser[_address];
    }


    function enableContract(bool _bool) public onlyOwner() {
        contractEnabled = _bool;
    }

    function withdraw(uint256 _weiAmount) public onlyOwner() {
        payable(msg.sender).transfer(_weiAmount);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner() {
        uint256 HNYTotalAmount = HNYAddress.balanceOf(address(this));
        if (HNYTotalAmount > 0){
            HNYAddress.transfer(msg.sender, _amount);
        }
    }

}
