// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TGE is ERC20, Ownable, ReentrancyGuard {

    bool public isEnabled;
    uint256 public startTime; //Tempo unistamp em que o contrato foi inicializado;

    address constant ecosystemWallet = 0x079DEe37766f5336DB2D92312129fD42B6172138; //Carteira direcionada ao fundo do ecossitema; - 1 carteira 
    address constant publicSaleWallet = 0x08ADb3400E48cACb7d5a5CB386877B3A159d525C; //Carteira direcionada ao fundo do public sale; - 1 carteira
    address constant liquidityMMWallet = 0x85a46Fc742ceB17af89A7d29808a1b55ffc9D309; //Carteira direcionada aos fundos market maker; - 1 carteira
    address constant teamWallet = 0x43D30a7219530394102c382f67F45cEEb8dc8685; //Carteira direcionada aos fundo do time; - 1 carteira
    address constant privateSaleWallet = 0x65ec750abaE265Ebfa041ef1E5A4e518027E2E7A; //Carteira direcionada ao fundo do private sale; - 1 carteira
    address constant developmentWallet = 0xe9C523943388Afa93538b35C791Bc035CD2Ee485; //Carteira direcionada ao fundo do desenvolvimento; - 1 carteira
    address constant partnersWallet = 0x668515a06730f5696b99a84aA33CE70DDaeA4093; //Carteira direcionada ao fundo de parceiros; - 1 carteira
    address constant marketingWallet = 0xfd7F9f11eD8474D6C6bfF42941203DB702D72cf8; //Carteira direcionada ao fundo de marketing; - 1 carteira
    address constant initialStakingPool = 0x668515a06730f5696b99a84aA33CE70DDaeA4093; //Carteira direcionada ao fundo de staking inicial; - 1 carteira

    event contractStarted(uint256 timestamp); 

    //contador que relaciona o fundo com a quantidade de mints já realizados de acordo com o vesting.
    mapping(address => uint256) public walletToVestingCounter; 

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

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
        _mint(publicSaleWallet, 90_000_000_000000000000000000); //90.000.000 tokens
        _mint(initialStakingPool, 5_000_000_000000000000000000); //5.000.000 tokens
        _mint(liquidityMMWallet, 80_000_000_000000000000000000); //80.000.000 tokens
        _mint(teamWallet, 18_750_000_000000000000000000); //18.750.000 tokens
        _mint(privateSaleWallet, 8_250_000_000000000000000000); //8.250.000 tokens
        _mint(developmentWallet, 8_750_000_000000000000000000); //8.250.000 tokens
        _mint(partnersWallet, 6_250_000_000000000000000000); //6.250.000 tokens
        _mint(marketingWallet, 15_000_000_000000000000000000); //15.000.000 tokens

        emit contractStarted(startTime);
    }


    function withdrawPrivateSaleTokens() public nonReentrant isContractEnabled {
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

    function withdrawDevelopmentTokens() public nonReentrant isContractEnabled {
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

    function withdrawPartnersTokens() public nonReentrant isContractEnabled {
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

    function withdrawTeamTokens() public nonReentrant isContractEnabled {
        require(walletToVestingCounter[teamWallet] < 48, "Todos os tokens relacionados a este fundo ja foram mintados");

        if(startTime + 2_592_000 + (walletToVestingCounter[teamWallet] * 2_592_000) <= block.timestamp) {
            walletToVestingCounter[teamWallet] = walletToVestingCounter[teamWallet] + 1;
            _mint(teamWallet, 1_171_875_000000000000000000); 
        } else {
            revert("Fundos ainda nao liberados");
        }
 
    }
 
}
