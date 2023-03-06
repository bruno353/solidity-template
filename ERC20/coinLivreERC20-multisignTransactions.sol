// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract coinLivreERC20 is ERC20, ERC20Burnable {
    using Counters for Counters.Counter;


    mapping(uint256 => address) public owners;

    
    constructor(string memory _name, string memory _symbol, address _owner2, address _owner3)
        ERC20(_name, _symbol)
    {
        owners[0] = msg.sender;
        owners[1] = _owner2;
        owners[2] = _owner3;
        //_mint(msg.sender, 1000000000000000000000000000000000 * 10 ** 18);
    }

    modifier onlyOwners() {
        require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2], "You are not an owner");
        _;
    }

    //Mapping para determinar se o endereço em questão pertence a um grupo seleteo de endereços que podem manusear o token.
    mapping(address => bool) public isAllowed;

    function setIsAllowed(address _address, bool _bool) public onlyOwners {
        isAllowed[_address] = _bool;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(isAllowed[to] == true, "Address 'to' not allowed to manage tokens");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(isAllowed[to] == true, "Address 'to' not allowed to manage tokens");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }




    //MULTISIGN:
    //Para cada função que possui o multi-sign, deverá ser criado uma estrutura semelhante a essa 


    //MULTISIGN PARA MINTAR TOKENS
    //multisign baseado na regra 2/3: 3 master wallets, para uma transação passar precisa da assinatura de no mínimo 2 wallets.
    //toda vez que uma wallet (das 3 masterWallets) assinar a transação, guardamos que assinou.
    struct mintTokensTransaction {
        address to;
        uint256 amount;
        mapping(address => bool) addressToSign;
        bool executed;
        bool exists;
    }

    Counters.Counter public _mintTokensTransactionsIds;

    event mintTokensTransactionCreated(address to, uint256 amount);

    mapping(uint256 => mintTokensTransaction) public mintTokensTransactions;

    function createMintTokensTransaction(address _to, uint256 _amount) public onlyOwners {
        require(_amount > 0, "Amount should be greater than zero");

        _mintTokensTransactionsIds.increment();

        uint256 id = _mintTokensTransactionsIds.current();

        mintTokensTransactions[id].to = _to;
        mintTokensTransactions[id].amount = _amount;
        mintTokensTransactions[id].exists = true;

        emit mintTokensTransactionCreated(_to, _amount);
    }


    event mintTokensTransactionSigned(address signer);

    //Assinar a função, é necessário passar o id da struct da transação que vc quer assinar
    function signMintTokensTransaction(uint256 id) public onlyOwners {
        require(mintTokensTransactions[id].exists, "This transaction request does not exist");
        require(mintTokensTransactions[id].addressToSign[msg.sender] == false, "You already signed this transaction request");

        mintTokensTransactions[id].addressToSign[msg.sender] = true;

        emit mintTokensTransactionSigned(msg.sender);
    }
    
    //passar o id da struct que contém a requisição de transação
    function mintTokens(uint256 id) public onlyOwners {
        require(mintTokensTransactions[id].executed == false, "Transaction already executed");
        require(mintTokensTransactions[id].exists, "Transaction does not exists");

        uint256 counter;

        for(uint i = 0; i < 3; i++) {
            if(mintTokensTransactions[id].addressToSign[owners[i]]) {
                counter = counter + 1;
            }
        }

        if(counter >= 2) {
            _mint(mintTokensTransactions[id].to, mintTokensTransactions[id].amount);
            mintTokensTransactions[id].executed = true;
        }
    }

    function seeSomething(uint256 i, uint256 id) public view returns(bool) {
        return mintTokensTransactions[id].addressToSign[owners[i]];
    }






    //MULTISIGN PARA QUEIMAR TOKENS
     struct burnTokensTransaction {
        address to;
        uint256 amount;
        mapping(address => bool) addressToSign;
        bool executed;
        bool exists;
    }

    Counters.Counter public _burnTokensTransactionsIds;

    event burnTokensTransactionCreated(address to, uint256 amount);

    mapping(uint256 => burnTokensTransaction) public burnTokensTransactions;

    function createBurnTokensTransaction(address _to, uint256 _amount) public onlyOwners {
        require(_amount > 0, "Amount should be greater than zero");

        _burnTokensTransactionsIds.increment();

        uint256 id = _burnTokensTransactionsIds.current();

        burnTokensTransactions[id].to = _to;
        burnTokensTransactions[id].amount = _amount;
        burnTokensTransactions[id].exists = true;

        emit burnTokensTransactionCreated(_to, _amount);
    }


    event burnTokensTransactionSigned(address signer);

    //Assinar a função, é necessário passar o id da struct da transação que vc quer assinar
    function signBurnTokensTransaction(uint256 id) public onlyOwners {
        require(burnTokensTransactions[id].exists, "This transaction request does not exist");
        require(burnTokensTransactions[id].addressToSign[msg.sender] == false, "You already signed this transaction request");

        burnTokensTransactions[id].addressToSign[msg.sender] = true;

        emit burnTokensTransactionSigned(msg.sender);
    }

    event tokensBurned(address _address, uint256 amount);
    
    //passar o id da struct que contém a requisição de transação
    function burnTokens(uint256 id) public onlyOwners {
        require(burnTokensTransactions[id].executed == false, "Transaction already executed");
        require(burnTokensTransactions[id].exists, "Transaction does not exists");

        uint256 counter;

        for(uint i = 0; i < 3; i++) {
            if(burnTokensTransactions[id].addressToSign[owners[i]]) {
                counter = counter + 1;
            }
        }

        if(counter >= 2) {
            _burn(burnTokensTransactions[id].to, burnTokensTransactions[id].amount);
            burnTokensTransactions[id].executed = true;
            emit tokensBurned(burnTokensTransactions[id].to, burnTokensTransactions[id].amount);
        }
    }


    

}
