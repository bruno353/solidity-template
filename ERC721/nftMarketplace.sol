// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//contrato NFT com whitelist e marketplace embutido:

contract WeirdBandNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;
    Counters.Counter public _itemsSolds;
    uint256 public maxSupply;
    uint256 public maxNFTsPerWallet;
    bool public isEnabled;
    bool public isWhitelistOn;


    //quantidade de nfts mintados por carteira:
    mapping(address => uint256) public nftsMintedPerWallet;


    //3 Personagens, cada personagem pode ter 49 variações -> 147 tipos diferentes de nfts. 
    //Como são 1029 NFTs mintados ao todo, cada tipo de nft vai ter 7 mints, então temos que fazer essa contagem para
    //garantir o equilíbrio no mint dos nfts.
    mapping(uint256 => uint256) public NFTCharacterToCount;

    mapping(address => bool) public addressToBoolWl; //whitelist


    //random generator:
    function randomGenerator() public  returns(uint256){
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

        while(true){
            
            if(NFTCharacterToCount[nft] < 7) {
                NFTCharacterToCount[nft] = NFTCharacterToCount[nft] + 1;
                return(nft);
            }
            
            else {
                if(nft == 2){
                    nft = 0;
                    continue;
                }
                nft = nft + 1;
                
            }

        }
        return nft;
    }


    constructor (uint256 _maxSupply, uint256 _maxNFTsPerWallet) ERC721("Weird Band", "WB")  {
            maxSupply = _maxSupply;
            isWhitelistOn = true;
            maxNFTsPerWallet = _maxNFTsPerWallet;
    }


    //Creating the nfts struct:
    struct Item {
        uint256 id;
        string uri; //metadata url
        uint256 price;
        address seller;
    }
    

    event NFTMinted (uint256 id, string uri, address minter);

    mapping(uint256 => Item) public Items; //id => Item


    //nftsQuantity: quantidade de nfts que o user quer mintar.
    //preco do nft: 0.01 matics.
    function mintNFT(uint256 nftsQuantity) public payable {
        require(_tokenIds.current() < maxSupply, "The minting process reached the max supply");
        require(_tokenIds.current() + nftsQuantity <= maxSupply, "The minting process reached the max supply");
        require(msg.value == nftsQuantity * 10000000000000000, "The value isnt high enough to pay for the nfts");
        require(nftsMintedPerWallet[msg.sender] + nftsQuantity <= maxNFTsPerWallet, "You cannot mint that amount of nfts for one wallet");

        if(isWhitelistOn == true){
            require(addressToBoolWl[msg.sender] == true);
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
            nftsMintedPerWallet[msg.sender] = nftsMintedPerWallet[msg.sender] + nftsQuantity;

            Items[newItemId] = Item({
            id: newItemId, 
            uri: string(w2),
            price: 0,
            seller: msg.sender
            });

            emit NFTMinted(Items[newItemId].id, Items[newItemId].uri, msg.sender);

        }
        
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
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

    function getItemById(uint256 _tokenId) public view returns(Item memory){
        return Items[_tokenId];
    }

    function setContractEnabled(bool _bool) public onlyOwner {
        isEnabled = _bool;
    }

    function setIsWhitelistOn(bool _bool) public onlyOwner {
        isWhitelistOn = _bool;
    }

    //WHITELIST:
    event addressAddedToWhitelist(address _address);
    function addAddressToWhitelist(address _address) public onlyOwner {

        addressToBoolWl[_address] = true;

        emit addressAddedToWhitelist(_address);
    }


    event addressRemovedFromWhitelist(address _address);
    function removeAddressFromWhitelist(address _address) public onlyOwner {
        
        addressToBoolWl[_address] = false;

        emit addressRemovedFromWhitelist(_address);
    }


    //MARKETPLACE:


    event itemAddedForSale(uint256 id, uint256 price, address seller);
    event itemSold(uint256 id, uint256 price, address seller, address buyer);  





    function putItemForSale(uint256 _tokenId, uint256 _price) 
        external 
        payable {
        require(ownerOf(_tokenId) == msg.sender, "You are not the token owner");
        require(_price > 0 , "Price needs to be greater than 0");

        Items[_tokenId].price = _price;
        Items[_tokenId].seller = msg.sender;

        _transfer(msg.sender, address(this), _tokenId);

        emit itemAddedForSale(_tokenId, _price, msg.sender);
    }


    // Creates the sale of a marketplace item 
    function buyItem(uint256 _tokenId) 
        payable 
        external {
        require(_tokenIds.current() >= _tokenId, "NFT does not exist");
		require(ownerOf(_tokenId) == address(this), "You are not the token owner");
        require(msg.value >= Items[_tokenId].price, "Not enough funds sent");
        require(msg.sender != Items[_tokenId].seller, "The seller can not buy it");
        uint256 priceEmit = Items[_tokenId].price;

        Items[_tokenId].price = 0;


        _transfer(address(this), msg.sender, _tokenId);
        
        payable(Items[_tokenId].seller).transfer(msg.value * 97/100);


        _itemsSolds.increment();

        emit itemSold(_tokenId, priceEmit, Items[_tokenId].seller, msg.sender);

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


    function fundMe() public payable returns(uint256){}


}
