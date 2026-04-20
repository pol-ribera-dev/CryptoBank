// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Bank.sol";
import "../src/MultiUserAccount.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./UserNoRecive.t.sol";

// Test of MultiUserAccount.sol with 100% coverage

contract MultiUserAccountTest is Test {

    Bank bank;
    MultiUser account;
    uint256 maxBalance = 1 ether;
    address admin = vm.addr(1);
    address accountOwner = vm.addr(2);
    address randomUser = vm.addr(3);
    address randomUser2 = vm.addr(4);

    function setUp() public {
        bank = new Bank(maxBalance, admin);
        vm.startPrank(accountOwner);
        account = new MultiUser(address(bank));
        vm.stopPrank();
    }
    
    function testCorrectlyDeployed() external view { 
        assert(address(bank) != address(0)); 
        assert(address(account) != address(0));
        assert(account.userAllowed(accountOwner));
        assert(!account.userAllowed(randomUser));
    } 

    //DEPOSIT TESTS
    function testDepositCorrectly() external { 
        vm.startPrank(accountOwner);
        uint256 etherAmount = 0.5 ether;
        vm.deal(accountOwner, etherAmount);

        uint256 balanceAccountBefore = bank.userBalance(address(account));
        
        account.depositEther{value: etherAmount}();

        uint256 balanceAccountAfter = bank.userBalance(address(account));

        assert(balanceAccountAfter - balanceAccountBefore == etherAmount);
        
        vm.stopPrank();
    }

    function testDepositWithoutBeAllowed() external { 
        vm.startPrank(randomUser);
        uint256 etherAmount = 0.5 ether;
        vm.deal(randomUser, etherAmount);
        
        vm.expectRevert("Not allowed");

        account.depositEther{value: etherAmount}();
        
        vm.stopPrank();
    }

    // WITHDRAW TESTS
    function testWithdrawCorrectly() external { 
        vm.startPrank(accountOwner);
        uint256 etherAmount = 0.5 ether;
        vm.deal(accountOwner, etherAmount);

        account.depositEther{value: etherAmount}();

        uint256 balanceBeforeInBank = bank.userBalance(address(account));
        uint256 balanceBeforeOutBank = address(accountOwner).balance;

        account.withdrawEther(etherAmount);

        uint256 balanceAfterInBank = bank.userBalance(address(account));
        uint256 balanceAfterOutBank = address(accountOwner).balance;

        assert(balanceBeforeInBank == balanceAfterInBank + etherAmount);
        assert(balanceBeforeOutBank + etherAmount == balanceAfterOutBank);
        
        vm.stopPrank();
    }

    function testWithdrawWithoutBeAllowed() external { 
        vm.startPrank(accountOwner);
        uint256 etherAmount = 0.5 ether;
        vm.deal(accountOwner, etherAmount);
        account.depositEther{value: etherAmount}();
        vm.stopPrank();
        
        vm.expectRevert("Not allowed");

        vm.startPrank(randomUser);
        account.withdrawEther(etherAmount);
        vm.stopPrank();
    }

    // INVITATION TESTS
    function testInvitationCorrectly() external { 
        vm.startPrank(accountOwner);
        assert(!account.userAllowed(randomUser));
        account.invitation(randomUser);
        assert(account.userAllowed(randomUser));
        vm.stopPrank();
    }

    function testInvitationWithoutBeAllowed() external { 
        vm.startPrank(randomUser);
        vm.expectRevert("Not allowed");
        account.invitation(randomUser2);
        vm.stopPrank();
    }

    function testInvitationAgain() external { 
        vm.startPrank(accountOwner);
        assert(!account.userAllowed(randomUser));
        account.invitation(randomUser);
        assert(account.userAllowed(randomUser));
        account.invitation(randomUser);
        assert(account.userAllowed(randomUser));
        vm.stopPrank();
    }

    function testInvitationOwnself() external { 
        vm.startPrank(accountOwner);
        account.invitation(accountOwner);
        assert(account.userAllowed(accountOwner));
        vm.stopPrank();
    }

    function testInvitationOwnselfFail() external { 
        vm.startPrank(randomUser);
        vm.expectRevert("Not allowed");
        account.invitation(randomUser);
        vm.stopPrank();
    }

    // ELIMINATION TESTS
    function testEliminationCorrectly() external { 
        vm.startPrank(accountOwner);
        account.invitation(randomUser);
        assert(account.userAllowed(randomUser));
        account.elimination(randomUser);
        assert(!account.userAllowed(randomUser));
        vm.stopPrank();
    }
    function testEliminationWithoutBeAllowed() external { 
        vm.startPrank(randomUser);
        vm.expectRevert("Not allowed");
        account.elimination(accountOwner);
        vm.stopPrank();
    }
    function testEliminationOwnself() public { 
        vm.startPrank(accountOwner);
        assert(account.userAllowed(accountOwner));
        account.elimination(accountOwner);
        assert(!account.userAllowed(accountOwner));
        vm.stopPrank();
    }

    // COMPLEX TESTS
    function testOneDepopsitOtherDepositAndWithdrawAll() external { 
        uint256 etherAmount = 0.3 ether;
        vm.deal(accountOwner, etherAmount);
        vm.deal(randomUser, etherAmount);

        vm.startPrank(accountOwner);
        account.invitation(randomUser);
        account.depositEther{value: etherAmount}();
        vm.stopPrank();

        vm.startPrank(randomUser);

        account.depositEther{value: etherAmount}();

        uint256 balanceBeforeInBank = bank.userBalance(address(account));
        uint256 balanceBeforeOutBank = address(randomUser).balance;

        account.withdrawEther(etherAmount*2);

        uint256 balanceAfterInBank = bank.userBalance(address(account));
        uint256 balanceAfterOutBank = address(randomUser).balance;

        assert(balanceBeforeInBank == balanceAfterInBank + etherAmount*2);
        assert(balanceBeforeOutBank + etherAmount*2 == balanceAfterOutBank);
        
        vm.stopPrank();
    }

    function testOneInvitesOtherEliminate() external {
        vm.startPrank(accountOwner);
        account.invitation(randomUser);
        account.invitation(randomUser2);
        assert(account.userAllowed(randomUser2));
        vm.stopPrank();
        
        vm.startPrank(randomUser);
        account.elimination(randomUser2);
        assert(!account.userAllowed(randomUser2));
        vm.stopPrank();
    }

    function testDepositInPersonalWithdrawMultiAccount() external { 
        vm.startPrank(accountOwner);
        uint256 etherAmount = 0.5 ether;
        vm.deal(accountOwner, etherAmount);

        bank.depositEther{value: etherAmount}();
        vm.expectRevert("Not enough ether");
        account.withdrawEther(etherAmount);

        vm.stopPrank();
    }


    function testDepositMultiAccountWithdrawInPersonal() external { 
        vm.startPrank(accountOwner);
        uint256 etherAmount = 0.5 ether;
        vm.deal(accountOwner, etherAmount);

        account.depositEther{value: etherAmount}();
        vm.expectRevert("Not enough ether");
        bank.withdrawEther(etherAmount);

        vm.stopPrank();
    }

    function testReciveFail() external {
        UserTest userSimulation = new UserTest(payable(address(account)));
        uint256 etherAmount = 0.5 ether;

        vm.deal(address(userSimulation), etherAmount);
        vm.expectRevert(); 

        userSimulation.interact(etherAmount);
    }
}
