// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//to do: How to integrate in the minting function an Id card (but with privacy), so we know when someone dies but without exposing who it is to the blockchain?
//set a function: When the 10/5 years has passed and the person has not died, the payout backed is returned to the Insurance company.
//set a function: When the insured dies, who owns the NFT is paid with the total amount backed. -> this function can be set into the marketplace contract.

contract OnceToken is ERC721Enumerable{
  using Counters for Counters.Counter;

  Counters.Counter public _tokenIds;
  Counters.Counter private _insuredIds;
  address public marketplace;

  constructor () ERC721("OnceToken", "ONCE") {}

  //setting a governance oracle/DAO that will grants access for minting Once NFTs
  //So who pass the Once KYC system will have the permission for minting:
  address public ownerGovernance = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

  //Creating the insured structs:
  struct Insured {
    uint256 id;
    address insured;
  }

  event insuredGranted(uint256 id, address insured);

  mapping(uint256 => Insured) public Insureds;

  //So here, with the the governance address, we grant for the user the possibility to mint Once NFTs (after checking the KYC):
  function grantInsuranceMint(address _address) public returns(uint256){
    require(msg.sender == ownerGovernance, "Only the DAO governance can set this role");
    require(exists1(_address) == false, "This address already is granted");
    _insuredIds.increment();
    uint256 newInsuredId = _insuredIds.current();
    Insureds[newInsuredId] = Insured ({
      id: newInsuredId,
      insured: _address
    });

    emit insuredGranted(Insureds[newInsuredId].id, Insureds[newInsuredId].insured);
    return newInsuredId;
  }

  //remove grant to insured:
  function removeGrantToInsured(uint256 num) public{
    require(msg.sender == ownerGovernance, "Only the DAO governance can do it");
    delete Insureds[num];
  }

  //return Insured address by Id:
  function fetchInsured(uint256 num) public view returns(address){
    return Insureds[num].insured;
  }

  //function for checking if address is granted for minting
  function exists1(address _address) internal view returns (bool) {
    uint count = _insuredIds.current();
    for (uint i = 0; i < count + 1; i++) {
        if (Insureds[i].insured == _address) {
            return true;
        }
    }

    return false;
  }

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
    require(exists1(msg.sender) == true, "You are not an allowed insured");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(marketplace, newItemId);

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

  function autoPayoutCheck(uint256 _tokenId) public {
      require(msg.sender == ownerGovernance, "Only the ownerGovernance can trigger this function");
  
      // Assuming `expiryTime` is stored in the `Item` struct as a timestamp
      if (block.timestamp > Items[_tokenId].expiryTime) {
          if (Items[_tokenId].assuranceTriggered == false) {
              address payable insurer = payable(Items[_tokenId].insurer);
              uint256 payout = Items[_tokenId].payout - poolFee;
              Items[_tokenId].assuranceTriggered = true;
              (bool sent, ) = insurer.call{value: payout}("");
              require(sent, "Failed to return payout to insurer");
          }
      }
  }
  //now the Insurance company (or a single person) can do the payout payment (so the contract can allocate it into a liquidity pool for example) and "buy" the assurance:
  function buyInsurance(uint256 tokenId) public payable {
    require(msg.value == Items[tokenId].payout, "Value for backing the insurance incorrect");
    require(Items[tokenId].backed == false, "This insurance was already backed");
    Items[tokenId].backed = true;
    Items[tokenId].insurer = msg.sender;
    uint256 _premium = Items[tokenId].premium;

    //transfer the premium amount to the Insurance company and the value to the marketplace:
    (bool sent, ) = payable(msg.sender).call{value: _premium}("");
    require(sent, "Failed to send Ether/Matic");
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  function fetchPayoutAmount(uint256 tokenId) public view returns (uint256){
    return Items[tokenId].payout;
  }

  function setMarketplace(address market) public {
    require(msg.sender == ownerGovernance, "Only the DAO governance can set the marketplace");
    marketplace = market;
  }

  function fetchTokensIds() public view returns(uint256){
      return _tokenIds.current();
  }

  uint256 poolFee = 0.01 ether;
  function setPoolFee(uint256 _poolFee) public {
      require(msg.sender == ownerGovernance, "Only the ownerGovernance can set the pool's fee!!" );
      poolFee = _poolFee;
  }

  //getPayout is triggered when the insured dies - who owns the nft will get the payout:
  function getPayout(uint256 _tokenId) public {
    require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw!!");
    require(Items[_tokenId].assuranceTriggered == false, "This assurance was already called");

    address payable _to = payable(ownerOf(_tokenId));

    uint256 payout = Items[_tokenId].payout - poolFee;
    
    Items[_tokenId].assuranceTriggered = true;

    //transfer the payout amount to the NFT owner:
    (bool sent, ) = payable(_to).call{value: payout}("");
    require(sent, "Failed to send Ether/Matic");
  }

  //getAmountBack is triggered when the timestamp in the insurance contract has passed and the insured has not died, the money goes back to the insurer:
  function getAmountBack(uint256 _tokenId) public {
    require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw!!");  
    require(Items[_tokenId].assuranceTriggered == false, "This assurance was already called");

    address payable _to = payable(Items[_tokenId].insurer);

    uint256 payout = Items[_tokenId].payout - poolFee;

    Items[_tokenId].assuranceTriggered = true;

    //transfer the payout amount to the insurer:
    (bool sent, ) = payable(_to).call{value: payout}("");
    require(sent, "Failed to send Ether/Matic");
  }


}
