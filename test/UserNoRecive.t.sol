// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../src/MultiUserAccount.sol";

contract UserTest {

    MultiUser account;

    constructor(address payable _account) {
        account = MultiUser(_account);
    }

    function interact(uint256 _amount) external {
        account.depositEther{value: _amount}();
        account.withdrawEther(_amount);
    }

}