// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TGE is Ownable, ReentrancyGuard {

    ERC20 public soulPrimeToken;

    bool public isEnabled;
    uint256 public startTime; //Tempo unistamp em que o contrato foi inicializado;

    address public ecosystemWallet = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;//Carteira direcionada ao fundo do ecossitema;
    address public publicSaleWallet = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C; //Carteira direcionada ao fundo do public sale;
    address public liquidityMMWallet = 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC; //Carteira direcionada aos fundos market maker;
    address public teamWallet = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c; //Carteira direcionada aos fundo do time;
    address public privateSaleWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C; //Carteira direcionada ao fundo do private sale;
    address public developmentWallet = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; //Carteira direcionada ao fundo do desenvolvimento;
    address public partnersWallet = 0x583031D1113aD414F02576BD6afaBfb302140225; //Carteira direcionada ao fundo de parceiros;
    address public marketingWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //Carteira direcionada ao fundo de marketing;

    event contractStarted(uint256 timestamp); 

    //contador que relaciona o fundo com a quantidade de mints já realizados de acordo com o vesting.
    mapping(address => uint256) public walletToVestingCounter; 

    modifier isContractEnabled() {
        require(isEnabled, "Contrato nao iniciado");
        _;
    }

    //inicializa o contrato, mintando para as carteiras o montante acordado de ínício:
    function startContract() public onlyOwner {
        require(!isEnabled, "Contrato ja iniciado");
        isEnabled = true;
        startTime = block.timestamp;

        _initialTokenDistribution();

        emit contractStarted(startTime);
    }

    function _initialTokenDistribution() private { 
        uint256[8] memory tokenAmounts = [
            uint256(196_250_000_000000000000000000),
            uint256(95_000_000_000000000000000000),
            uint256(80_000_000_000000000000000000),
            uint256(18_750_000_000000000000000000),
            uint256(8_250_000_000000000000000000),
            uint256(8_750_000_000000000000000000),
            uint256(6_250_000_000000000000000000),
            uint256(15_000_000_000000000000000000)
        ];        
        address[8] memory wallets = [ecosystemWallet, publicSaleWallet, liquidityMMWallet, teamWallet, privateSaleWallet, developmentWallet, partnersWallet, marketingWallet];

        for (uint256 i = 0; i < wallets.length; i++) {
            soulPrimeToken.transfer(wallets[i], tokenAmounts[i]);
        }
    }

    function withdrawPrivateSaleTokens() public nonReentrant {
        //privateSale possui 3 vestings mints: after 90 days TGE 25%, after 180 days TGE 40%, after 210 days TGE 20%.
        require(walletToVestingCounter[privateSaleWallet] < 3, "All tokens related to this fund have been minted");

        uint256[3] memory vestingAmounts = [uint256(13_750_000_000000000000000000), uint256(22_000_000_000000000000000000), uint256(11_000_000_000000000000000000)];

        uint256[3] memory vestingDurations = [uint256(7_776_000), uint256(15_552_000), uint256(18_144_000)];

        _withdrawVestedTokens(privateSaleWallet, vestingAmounts, vestingDurations);
    }

    function withdrawDevelopmentTokens() public nonReentrant {
        //development possui 20 vestings mints após 12 meses de cliff: 5% ao mês.
        require(walletToVestingCounter[developmentWallet] < 20, "All tokens related to this fund have been minted");

        //12 meses = 31536000 segundos
        //considerando que um mês = 30 dias -> 2592000 segundos

        uint256 vestingAmount = 1_312_500_000000000000000000;
        uint256 cliffDuration = 31_536_000;
        uint256 monthlyDuration = 2_592_000;

        _withdrawVestedTokensWithCliff(developmentWallet, vestingAmount, cliffDuration, monthlyDuration);
    }

    function withdrawPartnersTokens() public nonReentrant {
        //partnerTokens possui 20 vestings mints após 12 meses de cliff: 5% ao mês.
        require(walletToVestingCounter[partnersWallet] < 20, "All tokens related to this fund have been minted");

        //12 meses = 31536000 segundos
        //considerando que um mês = 30 dias -> 2592000 segundos

        uint256 vestingAmount = 937_500_000000000000000000;
        uint256 cliffDuration = 31_536_000;
        uint256 monthlyDuration = 2_592_000;

        _withdrawVestedTokensWithCliff(partnersWallet, vestingAmount, cliffDuration, monthlyDuration);
    }

    function _withdrawVestedTokens(address wallet, uint256[3] memory amounts, uint256[3] memory durations) private {
        uint256 currentVesting = walletToVestingCounter[wallet];

        if (startTime + durations[currentVesting] <= block.timestamp) {
            walletToVestingCounter[wallet] = currentVesting + 1;
            bool sent = soulPrimeToken.transfer(wallet, amounts[currentVesting]);
            require(sent, "Failed to transfer");
        } else {
            revert("Funds not yet released");
        }
    }

    function _withdrawVestedTokensWithCliff(address wallet, uint256 amount, uint256 cliffDuration, uint256 monthlyDuration) private {
        uint256 currentVesting = walletToVestingCounter[wallet];

        if (startTime + cliffDuration + (currentVesting * monthlyDuration) <= block.timestamp) {
            walletToVestingCounter[wallet] = currentVesting + 1;
            bool sent = soulPrimeToken.transfer(wallet, amount);
            require(sent, "Failed to transfer");
        } else {
            revert("Funds not yet released");
        }
    }

    function setERC20Contract(address _address) public onlyOwner {
        soulPrimeToken = ERC20(_address);
    }
 
}
