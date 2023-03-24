// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract TGE is ERC20, Ownable, ReentrancyGuard {

    //dúvidas: 
    //team: "locked staking 4 yers" o que isso significa? Durante os 4 anos o time não terá acesso a esse montante e no final ele terá acesso ao montante + juros?
    //development e partners: "25% TGE, 12 months cliff then 5% monthly" Após os 12 messes de cliff ele já receberá instantaneamente 5% do fundo, ou deverá esperar um mês para receber os 5% e assim por diante?



    bool public isEnabled;
    uint256 public startTime; //Tempo unistamp em que o contrato foi inicializado;

    address public ecosystemWallet;//Carteira direcionada ao fundo do ecossitema;
    address public publicSaleWallet; //Carteira direcionada ao fundo do public sale;
    address public liquidityMMWallet; //Carteira direcionada aos fundos market maker;
    address public teamWallet; //Carteira direcionada aos fundo do time;
    address public privateSaleWallet; //Carteira direcionada ao fundo do private sale;
    address public developmentWallet; //Carteira direcionada ao fundo do desenvolvimento;
    address public partnersWallet; //Carteira direcionada ao fundo de parceiros;
    address public marketingWallet; //Carteira direcionada ao fundo de marketing;

    event contractStarted(uint256 timestamp); 

    //contador que relaciona o fundo com a quantidade de mints já realizados de acordo com o vesting.
    mapping(address => uint256) public walletToVestingCounter; 

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
    }

    modifier isContractEnabled() {
        require(isEnabled, "Contrato nao iniciado");
        _;
    }

    //inicializa o contrato, mintando para as carteiras o montante acordado de ínício:
    function startContract() public onlyOwner {
        require(!isEnabled, "Contrato ja iniciado");
        isEnabled = true;
        startTime = block.timestamp;

        _mint(ecosystemWallet, 140_000_000_000000000000000000); //140.000.000 tokens
        _mint(publicSaleWallet, 95_000_000_000000000000000000); //95.000.000 tokens
        _mint(liquidityMMWallet, 80_000_000_000000000000000000); //80.000.000 tokens
        _mint(teamWallet, 18_750_000_000000000000000000); //18.750.000 tokens
        _mint(privateSaleWallet, 8_250_000_000000000000000000); //8.250.000 tokens
        _mint(developmentWallet, 8_750_000_000000000000000000); //8.250.000 tokens
        _mint(partnersWallet, 6_250_000_000000000000000000); //6.250.000 tokens
        _mint(marketingWallet, 15_000_000_000000000000000000); //15.000.000 tokens

        emit contractStarted(startTime);
    }


    function withdrawPrivateSaleTokens() public nonReentrant {
        //privateSale possui 3 vestings mints: after 90 days TGE 25%, after 180 days TGE 40%, after 210 days TGE 20%.
        require(walletToVestingCounter[privateSaleWallet] < 3, "Todos os tokens relacionados a este fundo ja foram mintados");

        if(walletToVestingCounter[privateSaleWallet] == 0) {
            //para o primeiro saque, deve-se ter passado 90 dias.
            if(startTime + 7_776_000 <= block.timestamp) {
                walletToVestingCounter[privateSaleWallet] = 1;
                _mint(privateSaleWallet, 13_750_000_000000000000000000);
            } else {
                revert("Fundos ainda nao liberados");
            }
        
        } else if(walletToVestingCounter[privateSaleWallet] == 1) {
            //para o segundo saque, deve-se ter passado 180 dias.
            if(startTime + 15_552_000 <= block.timestamp) {
                walletToVestingCounter[privateSaleWallet] = 2;
                _mint(privateSaleWallet, 22_000_000_000000000000000000);
            } else {
                revert("Fundos ainda nao liberados");
            }
        } else {
            //para o terceiro saque, deve-se ter passado 210 dias.
            if(startTime + 18_144_000 <= block.timestamp) {
                walletToVestingCounter[privateSaleWallet] = 3;
                _mint(privateSaleWallet, 11_000_000_000000000000000000);
            } else {
                revert("Fundos ainda nao liberados");
            }
        }
    }

    function withdrawDevelopmentTokens() public nonReentrant {
        //development possui 20 vestings mints após 12 meses de cliff: 5% ao mês.
        require(walletToVestingCounter[developmentWallet] < 20, "Todos os tokens relacionados a este fundo ja foram mintados");


        //12 meses = 31536000 segundos
        //considerando que um mês = 30 dias -> 2592000 segundos

        if(startTime + 31_536_000 + (walletToVestingCounter[developmentWallet] * 2_592_000) <= block.timestamp) {
                walletToVestingCounter[developmentWallet] = walletToVestingCounter[developmentWallet] + 1;
                _mint(developmentWallet, 1_312_500_000000000000000000);
        } else {
            revert("Fundos ainda nao liberados");
        }

    }

    function withdrawPartnersTokens() public nonReentrant {
        //privateSale possui 20 vestings mints após 12 meses de cliff: 5% ao mês.
        require(walletToVestingCounter[partnersWallet] < 20, "Todos os tokens relacionados a este fundo ja foram mintados");


        //12 meses = 31536000 segundos
        //considerando que um mês = 30 dias -> 2592000 segundos

        if(startTime + 31_536_000 + (walletToVestingCounter[partnersWallet] * 2_592_000) <= block.timestamp) {
                walletToVestingCounter[partnersWallet] = walletToVestingCounter[partnersWallet] + 1;
                _mint(partnersWallet, 937_500_000000000000000000);
        } else {
            revert("Fundos ainda nao liberados");
        }

    }
 
}
