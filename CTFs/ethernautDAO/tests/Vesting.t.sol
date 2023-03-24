// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "src/blocklize/soulprime/Token.sol";

contract TGET is Test {
    TGE tGE;
    address caller = makeAddr('caller');

    function setUp() public {
        vm.deal(caller, 10_000 ether);
        vm.startPrank(caller, caller);
        tGE = new TGE("Soulprime Token", "TGE");
        tGE.startContract();
        vm.stopPrank();
    }

    function testTryToWithdrawDevelopment() public {
        console.log(tGE.balanceOf(tGE.developmentWallet()));
        console.log(block.timestamp);
        vm.warp(block.timestamp + 31536000);
        console.log(block.timestamp);
        tGE.withdrawDevelopmentTokens();
        uint256 amountTokensDev = tGE.balanceOf(tGE.developmentWallet());
        console.log(amountTokensDev);

        for (uint i = 1; i < 20; i++ ) {
            vm.warp(block.timestamp + 2_592_000);
            tGE.withdrawDevelopmentTokens();
            amountTokensDev = tGE.balanceOf(tGE.developmentWallet());
            console.log(amountTokensDev);
        }
        assertEq(amountTokensDev, 35000000000000000000000000);

    }

    function testWithdrawPartnersTokens() public {
        console.log(tGE.balanceOf(tGE.partnersWallet()));
        console.log(block.timestamp);
        vm.warp(block.timestamp + 31536000);
        console.log(block.timestamp);
        tGE.withdrawPartnersTokens();
        uint256 amountTokensPartners = tGE.balanceOf(tGE.partnersWallet());
        console.log(amountTokensPartners);

        for (uint i = 1; i < 20; i++ ) {
            vm.warp(block.timestamp + 2_592_000);
            tGE.withdrawPartnersTokens();
            amountTokensPartners = tGE.balanceOf(tGE.partnersWallet());
            console.log(amountTokensPartners);
        }
        assertEq(amountTokensPartners, 25000000000000000000000000);

    }

    function testWithdrawPrivateSaleTokens() public {
        console.log(tGE.balanceOf(tGE.privateSaleWallet()));
        console.log(block.timestamp);
        uint256 startTimeTest = block.timestamp;
        uint256 amountTokensPrivateSale = tGE.balanceOf(tGE.privateSaleWallet());
        console.log(amountTokensPrivateSale);

        //para o primeiro saque, deve-se ter passado 90 dias.
        vm.warp(startTimeTest + 7776000);
        tGE.withdrawPrivateSaleTokens();

        //para o segundo saque, deve-se ter passado 180 dias.
        vm.warp(startTimeTest + 15552000);
        tGE.withdrawPrivateSaleTokens();

        //para o terceiro saque, deve-se ter passado 210 dias.
        vm.warp(startTimeTest + 18144000);
        tGE.withdrawPrivateSaleTokens();

        amountTokensPrivateSale = tGE.balanceOf(tGE.privateSaleWallet());
        console.log(amountTokensPrivateSale);
        assertEq(amountTokensPrivateSale, 55000000000000000000000000);

    }


}
