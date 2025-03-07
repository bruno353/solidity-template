// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

/**
 * @title ITransfer
 * @dev Interface de contrato para funções de transferência
 */
interface ITransfer {
    /**
     * @notice Transfere uma quantidade específica de tokens para o endereço fornecido
     * @param recipient O endereço para receber os tokens
     * @param amount A quantidade de tokens para transferir
     * @return true se a operação for bem-sucedida, false caso contrário
     */
    function transfer(address recipient, uint amount) external returns (bool);
}

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error ContractIsEnabled(bool);

/**
 * @title TGE
 * @dev Contrato de alocação de token e liberação de fundos
 * @author Soulprime team
 */
contract TGE is Ownable, ReentrancyGuard {

    ITransfer public soulPrimeToken;

    bool public isEnabled;
    uint public startTime; 

    uint[3]  vestingAmountsPrivateSale = [uint(13_750_000 ether), uint(22_000_000 ether), uint(11_000_000 ether)];
    uint[3]  vestingDurationsPrivateSale = [uint(7_776_000), uint(15_552_000), uint(18_144_000)];

    uint cliffDurationWithdraw = 365 days;
    uint monthlyDurationWithdraw = 30 days;

    uint vestingAmountDevelopment = 1_312_500 ether;
    uint vestingAmountPartners = 937_500 ether;
    uint vestingAmountTeam = 1_171_875 ether;

    address public ecosystemWallet = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;//Carteira direcionada ao fundo do ecossitema;
    address public publicSaleWallet = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C; //Carteira direcionada ao fundo do public sale;
    address public liquidityMMWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; //Carteira direcionada aos fundos market maker;
    address public teamWallet = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c; //Carteira direcionada aos fundo do time;
    address public privateSaleWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C; //Carteira direcionada ao fundo do private sale;
    address public developmentWallet = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; //Carteira direcionada ao fundo do desenvolvimento;
    address public marketingWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //Carteira direcionada ao fundo de marketing;
    address public partnersWallet = 0x583031D1113aD414F02576BD6afaBfb302140225; //Carteira direcionada ao fundo de parceiros;

    event contractStarted(uint timestamp); 
    event tokensWithdrawed(address wallet, uint amount);


    mapping(address => uint) public walletToVestingCounter; 

    /**
     * @dev Garante que o contrato esteja ativado
     */
    modifier isContractEnabled() {
        if (!isEnabled) { 
        revert ContractIsEnabled(isEnabled);
        }
        _;  
    }

    /**
     * @notice Inicia o contrato e distribui os tokens inicialmente
     * @dev Apenas o proprietário pode chamar essa função
     * @param _address Endereço do contrato ERC20
     */
    function startContract(address _address) public {
        soulPrimeToken = ITransfer(_address);
        isEnabled = true;
        startTime = block.timestamp;

        _initialTokenDistribution();

        emit contractStarted(startTime);
    }

    /**
     * @dev Realiza a distribuição inicial de tokens
     */
    function _initialTokenDistribution() private { 
        uint[8] memory tokenAmounts = [
            uint(1400_000_000 ether),
            uint(95_000_000 ether),
            uint(60_000_000 ether),
            uint(18_750_000 ether),
            uint(8_250_000 ether),
            uint(8_750_000 ether),
            uint(6_250_000 ether),
            uint(15_000_000 ether)
        ];        
        address[8] memory wallets = [ecosystemWallet, publicSaleWallet, liquidityMMWallet, teamWallet, privateSaleWallet, developmentWallet, partnersWallet, marketingWallet];

        for (uint i = 0; i < wallets.length; i++) {
            soulPrimeToken.transfer(wallets[i], tokenAmounts[i]);
        }
    }

    /**
     * @notice Retira tokens de venda privada
     * @dev Esta função é protegida contra reentrância
     */
    function withdrawPrivateSaleTokens() public {

        _withdrawVestedTokens(privateSaleWallet, vestingAmountsPrivateSale, vestingDurationsPrivateSale);
    }


    function withdrawDevelopmentTokens() public isContractEnabled {
        if(walletToVestingCounter[developmentWallet] == 20) {
            revert("All tokens related to this fund have been minted");
        }
    }

    /**
     * @notice Retira tokens de parceiros
     * @dev Esta função é protegida contra reentrância
     */
    function withdrawPartnersTokens() public nonReentrant isContractEnabled {
        if(walletToVestingCounter[partnersWallet] == 20) {
            revert("All tokens related to this fund have been minted");
        }

        _withdrawVestedTokensWithCliff(partnersWallet, vestingAmountPartners, cliffDurationWithdraw, monthlyDurationWithdraw);
    }

     /**
     * @notice Retira tokens do time - após a inicialização do contrato ele saca a quantidade de tokens mensalmente
     * @dev Esta função é protegida contra reentrância
     */
    function withdrawTeamTokens() public isContractEnabled {
        if(walletToVestingCounter[partnersWallet] == 48) {
            revert("All tokens related to this fund have been minted");
        }

        _withdrawVestedTokensWithCliff(teamWallet, vestingAmountTeam, 30 days, monthlyDurationWithdraw);
    }

    /**
     * @dev Retira tokens adquiridos
     * @param wallet Endereço da carteira de destino
     * @param amounts Quantidades para os períodos de vesting
     * @param durations Durações dos períodos de vesting
     */
    function _withdrawVestedTokens(address wallet, uint[3] memory amounts, uint[3] memory durations) {
        uint currentVesting = walletToVestingCounter[wallet];

        if (startTime + durations[currentVesting] <= block.timestamp) {
            walletToVestingCounter[wallet] = currentVesting + 1;
            bool sent = soulPrimeToken.transfer(wallet, amounts[currentVesting]);
            if(!sent) {
                revert("Failed to transfer");
            }
            emit tokensWithdrawed(wallet, amounts[currentVesting]);
        } else {
            revert("Funds not yet released");
        }
    }

    /**
     * @dev Retira tokens adquiridos com período de bloqueio (cliff)
     * @param wallet Endereço da carteira de destino
     * @param amount Quantidade de tokens
     * @param cliffDuration Duração do período de bloqueio
     * @param monthlyDuration Duração mensal após o período de bloqueio
     */
    function _withdrawVestedTokensWithCliff(address wallet, uint amount, uint cliffDuration, uint monthlyDuration) public {
        uint currentVesting = walletToVestingCounter[wallet];

        if (startTime + cliffDuration + (currentVesting * monthlyDuration) <= block.timestamp) {
            walletToVestingCounter[wallet] = currentVesting + 1;
            bool sent = soulPrimeToken.transfer(wallet, amount);
            if(!sent) {
                revert("Failed to transfer");
            }        
            emit tokensWithdrawed(wallet, amount);
        } else {
            revert("Funds not yet released");
        }
    }
 
}
