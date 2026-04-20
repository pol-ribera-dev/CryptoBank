// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Bank.sol";
import "./Reentrancy.t.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Test of Bank.sol with 100% coverage

contract BankTest is Test {

    Bank bank;
    uint256 maxBalance = 1 ether;
    address admin = vm.addr(1);
    address randomUser = vm.addr(2);
    address randomUser2 = vm.addr(3);

    function setUp() public {
        bank = new Bank(maxBalance, admin);
    }

    function testBankCorrectlyDeployed() external view { 
        assert(address(bank) != address(0)); 
        assert(bank.maxBalance() == maxBalance);
        assert(bank.admin() == admin);
    } 

    //DEPOSIT TESTS
    function testFuzzDeposit(uint256 etherAmount) external {
        vm.assume(etherAmount <= 1 ether);
        
        vm.startPrank(randomUser);
        vm.deal(randomUser, etherAmount);

        uint256 userBalanceBefore = bank.userBalance(randomUser);
        uint256 balanceBefore = address(bank).balance;

        bank.depositEther{value: etherAmount}();
        
        uint256 balanceAfter = address(bank).balance;
        uint256 userBalanceAfter = bank.userBalance(randomUser);

        assert(userBalanceAfter - userBalanceBefore == etherAmount);
        assert(balanceAfter - balanceBefore == etherAmount);
        
        vm.stopPrank();
    }

    function testTwoDepositsCorrectly() external {
        vm.startPrank(randomUser);
        uint256 etherAmount = 0.5 ether;
        uint256 etherToDeposit = 0.1 ether;
        vm.deal(randomUser, etherAmount);

        uint256 userBalanceBefore = bank.userBalance(randomUser);
        uint256 balanceBefore = address(bank).balance;
        
      
        bank.depositEther{value: etherToDeposit}();
        bank.depositEther{value: etherToDeposit}();

        uint256 balanceAfter = address(bank).balance;
        uint256 userBalanceAfter = bank.userBalance(randomUser);

        assert(userBalanceAfter - userBalanceBefore == etherToDeposit * 2);
        assert(balanceAfter - balanceBefore == etherToDeposit * 2);
        
        vm.stopPrank();
    }

    function testDepositMoreThanMaxBalance() external {
        // amount to deposit is bigger than Max_Balance
        vm.startPrank(randomUser);
        uint256 etherAmount = 2 ether;
        uint256 etherToDeposit = 1.5 ether;
        vm.deal(randomUser, etherAmount);
        
        vm.expectRevert("MaxBalance reached");
        
        bank.depositEther{value: etherToDeposit}();

        vm.stopPrank();
    }

    function testDepositPassingMaxBalance() external {
        // When we deposit the result is bigger than Max_Balance
        vm.startPrank(randomUser);
        uint256 etherAmount = 2 ether;
        uint256 etherToDeposit = 0.6 ether;
        vm.deal(randomUser, etherAmount);
        
        bank.depositEther{value: etherToDeposit}();

        vm.expectRevert("MaxBalance reached");

        bank.depositEther{value: etherToDeposit}();
        
        vm.stopPrank();
    }

    function testMultipleUsersDeposit() external {
        uint256 etherAmount1 = 0.6 ether;
        uint256 etherAmount2 = 0.7 ether;
        
        vm.deal(randomUser, etherAmount1);
        vm.deal(randomUser2, etherAmount2);

        uint256 user1BalanceBefore = bank.userBalance(randomUser);
        uint256 user2BalanceBefore = bank.userBalance(randomUser2);
        uint256 totalBalanceBefore = address(bank).balance;

        vm.prank(randomUser);
        bank.depositEther{value: etherAmount1}();
        vm.stopPrank();

        vm.prank(randomUser2);
        bank.depositEther{value: etherAmount2}();
        vm.stopPrank();

        uint256 user1BalanceAfter = bank.userBalance(randomUser);
        uint256 user2BalanceAfter = bank.userBalance(randomUser2);
        uint256 totalBalanceAfter = address(bank).balance;


        assert(user1BalanceAfter - user1BalanceBefore == etherAmount1);
        assert(user2BalanceAfter - user2BalanceBefore == etherAmount2);
        assert(totalBalanceAfter - totalBalanceBefore == etherAmount1 + etherAmount2);
    }

        function testDepositWithMoreThanMaxBalance() external {
        // There is the possibility to have more than MaxBalance in account,
        // so what happen if we try to deposit in that case. (It has to revert)
        uint256 newMaxBalance = 0.1 ether;
        uint256 etherAmount = 0.4 ether;

        vm.startPrank(randomUser);
        vm.deal(randomUser, etherAmount*2);
        bank.depositEther{value: etherAmount}();
        vm.stopPrank();

        vm.startPrank(admin);
        bank.modifyMaxBalance(newMaxBalance);
        vm.stopPrank();

        vm.expectRevert("MaxBalance reached");

        vm.startPrank(randomUser);
        bank.depositEther{value: etherAmount}();
        vm.stopPrank();
    }

    // WITHDRAW TESTS
    function testWithdrawCorrectly() external {
        vm.startPrank(randomUser);
        uint256 etherAmount = 0.5 ether;
        vm.deal(randomUser, etherAmount);

        bank.depositEther{value: etherAmount}();

        uint256 balanceBeforeInBank = bank.userBalance(randomUser);
        uint256 balanceBeforeOutBank = address(randomUser).balance;

        bank.withdrawEther(etherAmount);

        uint256 balanceAfterInBank = bank.userBalance(randomUser);
        uint256 balanceAfterOutBank = address(randomUser).balance;

        assert(balanceBeforeInBank == balanceAfterInBank + etherAmount);
        assert(balanceBeforeOutBank + etherAmount == balanceAfterOutBank);
        
        vm.stopPrank();
    }

    function testTwoWithdrawCorrectly() external {
        vm.startPrank(randomUser);
        uint256 etherAmount = 0.5 ether;
        uint256 etherWithdraw = 0.2 ether;
        vm.deal(randomUser, etherAmount);

        bank.depositEther{value: etherAmount}();

        uint256 balanceBeforeInBank = bank.userBalance(randomUser);
        uint256 balanceBeforeOutBank = address(randomUser).balance;

        bank.withdrawEther(etherWithdraw);
        bank.withdrawEther(etherWithdraw);

        uint256 balanceAfterInBank = bank.userBalance(randomUser);
        uint256 balanceAfterOutBank = address(randomUser).balance;

        assert(balanceBeforeInBank == balanceAfterInBank + etherWithdraw*2);
        assert(balanceBeforeOutBank + etherWithdraw*2 == balanceAfterOutBank);
        
        vm.stopPrank();
    }

    function testWithdrawWithoutDeposit() external {
        vm.startPrank(randomUser);
        uint256 etherAmount = 0.5 ether;

        vm.expectRevert("Not enough ether");

        bank.withdrawEther(etherAmount);
        
        vm.stopPrank();
    }

    function testWithdrawInsufficientBalance() external {
        vm.startPrank(randomUser);
        uint256 etherAmount = 0.5 ether;
        uint256 etherWithdraw = 0.6 ether;

        vm.deal(randomUser, etherAmount);
        bank.depositEther{value: etherAmount}();

        vm.expectRevert("Not enough ether");
        bank.withdrawEther(etherWithdraw);
        
        vm.stopPrank();
    }

    function testMultipleUsersWithdraw() external {
        uint256 etherAmount1 = 0.6 ether;
        uint256 etherAmount2 = 0.7 ether;
        
        vm.deal(randomUser, etherAmount1);
        vm.deal(randomUser2, etherAmount2);

        vm.prank(randomUser);
        bank.depositEther{value: etherAmount1}();
        vm.stopPrank();

        vm.prank(randomUser2);
        bank.depositEther{value: etherAmount2}();
        vm.stopPrank();

        vm.prank(randomUser);
        bank.withdrawEther(etherAmount1);
        vm.stopPrank();

        uint256 balanceUser1Bank = bank.userBalance(randomUser);
        uint256 balanceUser2Bank = bank.userBalance(randomUser2);
        uint256 balanceUser1Real = address(randomUser).balance;
        uint256 balanceBankTotal = address(bank).balance;

        assert(balanceUser1Bank == 0);
        assert(balanceUser2Bank == etherAmount2);
        assert(balanceUser1Real == etherAmount1);
        assert(balanceBankTotal == etherAmount2);
    }

    function testWithdrawCorrectlyMoreThanMaxBalance() external {
        // There is the possibility to have more than MaxBalance in account,
        // so what happen if we try to withdraw in that case.
        uint256 newMaxBalance = 0.1 ether;
        uint256 etherAmount = 0.5 ether;

        vm.startPrank(randomUser);
        vm.deal(randomUser, etherAmount);
        bank.depositEther{value: etherAmount}();
        vm.stopPrank();

        uint256 balanceBeforeInBank = bank.userBalance(randomUser);
        uint256 balanceBeforeOutBank = address(randomUser).balance;

        vm.startPrank(admin);
        bank.modifyMaxBalance(newMaxBalance);
        vm.stopPrank();

        assert(bank.maxBalance() < bank.userBalance(randomUser));

        vm.startPrank(randomUser);
        bank.withdrawEther(etherAmount);
        vm.stopPrank();

        uint256 balanceAfterInBank = bank.userBalance(randomUser);
        uint256 balanceAfterOutBank = address(randomUser).balance;

        assert(balanceBeforeInBank == balanceAfterInBank + etherAmount);
        assert(balanceBeforeOutBank + etherAmount == balanceAfterOutBank);
    }

    // MAX_BALANCE TESTS
    function testShouldChangeMaxBalance() external {
        vm.startPrank(admin);
        uint256 newMaxBalance = 2 ether;

        uint256 maxBalanceBefore = bank.maxBalance();
        bank.modifyMaxBalance(newMaxBalance);
        uint256 maxBalanceAfter = bank.maxBalance();

        assert(maxBalanceBefore != maxBalanceAfter);
        assert(maxBalanceAfter == newMaxBalance);

        vm.stopPrank();
    }

    function testJustAdminCanChangeMaxBalance() external {
        vm.startPrank(randomUser);
        uint256 newMaxBalance = 2 ether;

        vm.expectRevert("Not allowed");

        bank.modifyMaxBalance(newMaxBalance);

        vm.stopPrank();
    }

    // COMPLEX TESTS
    function testReentrancyAttackFails() external {
        // Simulation of a Reentrancy Attack
        Reentrancy attacker = new Reentrancy(address(bank));

        vm.deal(address(attacker), 1 ether);
        vm.expectRevert();

        attacker.attack();
    }
}
