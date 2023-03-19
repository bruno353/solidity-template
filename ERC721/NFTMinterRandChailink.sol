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

//random Chailink:
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @dev Contrato de mint randômico WeirdBand.
 *
 * Este contrato possui módulos de:
 *
 * - Randomização pela chailink
 * - Sub-coleções em um contrato
 * - Modularização de sub-coleções
 *
 */
contract WeirdBandNFT is VRFConsumerBaseV2, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter public _tokenIds;
    Counters.Counter public _itemsSolds;
    Counters.Counter public _NFTsMintedByOwner;
    uint256 public maxSupply = 3333;
    uint256 public nftPrice;
    bool public isEnabled;
    bool public isWhitelistOn;
    uint256 public collectionNFT = 0; //Controlar em qual sub-coleção se encontra.

    uint256[] public nftsRare = [1, 2, 3];
    uint256[] public nftsComum = [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];

    //divisão porcentagens:
    uint256 public maxNumberNFTsCountRare = 12;
    uint256 public maxNumberNFTsCountComum = 157;


    //quantidade de nfts mintados por carteira:
    mapping(uint256 => mapping(address => uint256)) public nftsMintedPerWallet;

    mapping(uint256 => uint256) public maxNFTsOwnerPerCollection;
    mapping(uint256 => uint256) public maxNFTsPerCollection;


    mapping(uint256 => uint256) public NFTCharacterToCount;

    constructor (
        uint256 _maxNFTsPerWallet, 
        uint256 _nftPrice,        
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_
        ) 
        VRFConsumerBaseV2(vrfCoordinator_)
        ERC721("Weird Band", "WB")  {

            isWhitelistOn = true;
            nftPrice = _nftPrice;
            maxNFTsOwnerPerCollection[0] = 333;
            maxNFTsPerCollection[0] = _maxNFTsPerWallet;

            //Chailink:
            _coordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
            _subscriptionId = subscriptionId_;
            _vrfCoordinator = vrfCoordinator_;
            _keyHash = keyHash_;

    }
    
    event NFTMinted (uint256 id, string uri, address minter);

    function mintNFT(uint32 nftsQuantity, bytes memory _signature) public  payable nonReentrant returns (uint256[] memory) {
        require(isEnabled, "The contract is not enabled");
        require(_tokenIds.current() < maxSupply, "The minting process reached the max supply");
        require(_tokenIds.current() + nftsQuantity <= maxSupply, "The minting process reached the max supply");
        require(msg.value == nftsQuantity * nftPrice, "The value isnt high enough to pay for the nfts");
        if(isWhitelistOn) {
            require(nftsMintedPerWallet[collectionNFT][msg.sender] + nftsQuantity <= maxNFTsPerCollection[collectionNFT], "You cannot mint that amount of nfts for one wallet");
        }

        if(isWhitelistOn){
            //verificando se o user tem nome na whitelist (através do método de assinatura)
            require(isMessageValid(_signature), "You are not whitelisted");
        }
            requestId = _coordinator.requestRandomWords(
                _keyHash,
                _subscriptionId,
                _REQUEST_CONFIRMATIONS,
                _CALLBACK_GAS_LIMIT,
                nftsQuantity
            );
            requestIdToAddress[requestId] = msg.sender;
        for (uint i = 0; i < nftsQuantity; i++) {
            nftsMintedPerWallet[collectionNFT][msg.sender] = nftsMintedPerWallet[collectionNFT][msg.sender] + 1;
            _tokenIds.increment();
            requestIdToTokenId[requestId].push( _tokenIds.current());
            emit RequestedRandomness(requestId);
        }
        return(requestIdToTokenId[requestId]);
    }

    function removeNFTFromArrayRare(uint _index) private {
        require(_index < nftsRare.length, "index out of bound");

        for (uint i = _index; i < nftsRare.length - 1; i++) {
            nftsRare[i] = nftsRare[i + 1];
        }
        nftsRare.pop();
    }

    function removeNFTFromArrayComum(uint _index) private {
        require(_index < nftsComum.length, "index out of bound");

        for (uint i = _index; i < nftsComum.length - 1; i++) {
            nftsComum[i] = nftsComum[i + 1];
        }
        nftsComum.pop();
    }

    function mintNFTOwner(uint32 nftsQuantity) public payable onlyOwner {
        require(_NFTsMintedByOwner.current() + nftsQuantity <= maxNFTsOwnerPerCollection[collectionNFT], "owner mints index out of bound"); 
        requestId = _coordinator.requestRandomWords(
                _keyHash,
                _subscriptionId,
                _REQUEST_CONFIRMATIONS,
                _CALLBACK_GAS_LIMIT,
                nftsQuantity
            );
        for (uint i = 0; i < nftsQuantity; i++) {
            requestIdToAddress[requestId] = msg.sender;
            _NFTsMintedByOwner.increment();
            _tokenIds.increment();
            requestIdToTokenId[requestId].push( _tokenIds.current());
            emit RequestedRandomness(requestId);
        }
        
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxNFTsPerWalletPerCollection(uint256 collection, uint256 _maxNFTsPerWallet) public onlyOwner {
        maxNFTsPerCollection[collection] = _maxNFTsPerWallet;
    }

    function setNftPrice(uint256 _nftPrice) public onlyOwner {
        nftPrice = _nftPrice;
    }

    function setTokenURI(string memory _tokenURI, uint256 _tokenId) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }


    function setContractEnabled(bool _bool) public onlyOwner {
        isEnabled = _bool;
    }

    function setIsWhitelistOn(bool _bool) public onlyOwner {
        isWhitelistOn = _bool;
    }


    function findIndexRare(uint num) public view returns (uint) {
        for (uint i = 0; i < nftsRare.length; i++) {
            if (nftsRare[i] == num) {
                return i;
            }
        }
        revert("Numero nao encontrado");
    }
    function findIndexComum(uint num) public view returns (uint) {
        for (uint i = 0; i < nftsComum.length; i++) {
            if (nftsComum[i] == num) {
                return i;
            }
        }
        revert("Numero nao encontrado");
    }

    //verification signatures:
    function isMessageValid(bytes memory _signature)
        public
        view
        returns (bool)
    {
        bytes32 messagehash = keccak256(
            abi.encodePacked(msg.sender, '0')
        );
        address signer = messagehash.toEthSignedMessageHash().recover(_signature);
        if (owner() == signer) {
            return (true);
        } else {
            return (false);
        } 
    }


    // Função para o owner retirar os fundos
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function fundMe() public payable returns(uint256){}

    //CHAILINK:

    mapping(uint256 => address) public requestIdToAddress;
    mapping(uint256 => uint256[]) public requestIdToTokenId;

    address private _vrfCoordinator;
    bytes32 private _keyHash;

    VRFCoordinatorV2Interface private _coordinator;

    uint64 private _subscriptionId;
    uint16 public constant _REQUEST_CONFIRMATIONS = 3;
    uint32 public  _CALLBACK_GAS_LIMIT = 2500000;
    uint256 public requestId;

    uint256[] private _randomWord;

    event RequestedRandomness(uint256 requestId);
    event ReceivedRandomness(uint256 requestId, uint256 number);


    function fulfillRandomWords(
        uint256 reqId_, /* requestId */
        uint256[] memory random_
    ) internal override {
        _randomWord = random_;
        for (uint i = 0; i < _randomWord.length; i++) {
            uint256 nft = _randomWord[0] % 100;

            if(((nft >= 0) && (nft < 1) && (nftsRare.length > 0)) || (nftsComum.length == 0)){
                uint256 nftFinal = _randomWord[i] % nftsRare.length;
                uint256[2] memory retorno = [0, nftFinal];
                mintCollectionNFT(retorno, requestIdToAddress[reqId_], requestIdToTokenId[reqId_][i]);
            } else {
                uint256 nftFinal = _randomWord[i] % nftsComum.length;
                uint256[2] memory retorno = [1, nftFinal];
                mintCollectionNFT(retorno, requestIdToAddress[reqId_], requestIdToTokenId[reqId_][i]);
            }
    
            emit ReceivedRandomness(reqId_, random_[0]);
        }
    }


    function mintCollectionNFT(uint256[2] memory numberR, address _address, uint256 tokenIdNFT) private {
        string memory h; 
        if(numberR[0] == 0){ 
            if(NFTCharacterToCount[nftsRare[numberR[1]]] < maxNumberNFTsCountRare) {
                h = Strings.toString(nftsRare[numberR[1]]);
                NFTCharacterToCount[nftsRare[numberR[1]]] = NFTCharacterToCount[nftsRare[numberR[1]]] + 1;
                if(NFTCharacterToCount[nftsRare[numberR[1]]] >= maxNumberNFTsCountRare) {
                    removeNFTFromArrayRare(numberR[1]);
                }
            }
            else {
                for (uint j = 1; j < 3; j++) {
                    if(NFTCharacterToCount[j] < maxNumberNFTsCountRare) {
                        h = Strings.toString(j);
                        NFTCharacterToCount[j] = NFTCharacterToCount[j] + 1;
                        if(NFTCharacterToCount[j] >= maxNumberNFTsCountRare) {
                            removeNFTFromArrayRare(findIndexRare(j));
                        }
                        break;
                    }
            }
            
        }
        } else {
            if(NFTCharacterToCount[nftsComum[numberR[1]]] < maxNumberNFTsCountComum) {
                h = Strings.toString(nftsComum[numberR[1]]);
                NFTCharacterToCount[nftsComum[numberR[1]]] = NFTCharacterToCount[nftsComum[numberR[1]]] + 1;
                if(NFTCharacterToCount[nftsComum[numberR[1]]] >= maxNumberNFTsCountComum) {
                    removeNFTFromArrayComum(numberR[1]);
                }
            } else{
                for (uint j = 4; j < 24; j++) {
                        if(NFTCharacterToCount[j] < maxNumberNFTsCountComum) {
                            h = Strings.toString(j);
                            NFTCharacterToCount[j] = NFTCharacterToCount[j] + 1;
                            if(NFTCharacterToCount[j] >= maxNumberNFTsCountComum) {
                                removeNFTFromArrayComum(findIndexComum(j));
                            }
                            break;
                        }
                }
                
            }
            
        }

        string memory str = "www.uri.com/";
        bytes memory w2 = abi.encodePacked(str, h);

        uint256 newItemId = tokenIdNFT;
        _safeMint(_address, newItemId);
        _setTokenURI(newItemId, string(w2));


        emit NFTMinted(_tokenIds.current(), string(w2), _address);
        
        }

        //CONTRACT CONFIG:
        function setConfig(uint256 _maxSupply, uint256 _nftPrice, uint256 _collectionNFT) public onlyOwner {
            maxSupply = _maxSupply;
            nftPrice = _nftPrice;
            collectionNFT = _collectionNFT;
        }

        function setArrays( uint256[] memory _nftsRare, uint256[] memory _nftsComum ) public onlyOwner {
            nftsRare = _nftsRare;
            nftsComum = _nftsComum;
        }

        function setParamsPercentage(uint256 _maxNumberNFTsCountRare, uint256 _maxNumberNFTsCountComum) public onlyOwner {
            maxNumberNFTsCountRare = _maxNumberNFTsCountRare;
            maxNumberNFTsCountComum = _maxNumberNFTsCountComum;
        }

        function setCallBackGasLimit( uint32 _value) public onlyOwner {
            _CALLBACK_GAS_LIMIT = _value;
        }
}
