// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Bank.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BankTest is Test {

    Bank bank;
    uint256 maxBalance = 1 ether;
    address admin = vm.addr(1);
    address randomUser = vm.addr(2);
    address randomUser2 = vm.addr(3);

    function setUp() public {
        bank = new Bank(maxBalance, admin);
    }

    // deploy correcte i setejat el user i el max

    // Deposit que funcioni
    // Deposit fail pk ja hi ha massa money
    // provar una cuantitat superior de una
    // i provar de fer dos deposits
    // deploy sense tindre fucking money man


    function testBankCorrectlyDeployed() external view { 
        assert(address(bank) != address(0)); 
    } // cal???

    function testFuzzDeposit(uint256 etherAmount) public {
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

    function testTwoDepositsCorrectly() public {
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

    function testDeployMoreThanMaxBalance() public {
        vm.startPrank(randomUser);
        uint256 etherAmount = 2 ether;
        uint256 etherToDeposit = 1.5 ether;
        vm.deal(randomUser, etherAmount);
        
        vm.expectRevert("MaxBalance reached");
        
        bank.depositEther{value: etherToDeposit}();

        vm.stopPrank();
    }

    function testDeployPassingMaxBalance() public {
        vm.startPrank(randomUser);
        uint256 etherAmount = 2 ether;
        uint256 etherToDeposit = 0.6 ether;
        vm.deal(randomUser, etherAmount);
        
        bank.depositEther{value: etherToDeposit}();

        vm.expectRevert("MaxBalance reached");

        bank.depositEther{value: etherToDeposit}();
        
        vm.stopPrank();
    }

    function testMultipleUsersDeposit() public {
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


    function testWithdrawCorrectly() public {
    
    }


/*




    //withdraw correcte
    // dos withdraws
    // provar sense posar diners
    // provar retirant mes diners 
    // pots retirar més que el maxim balance
    // un ffuzing test? DEPLOY MILLOR
    // 100% de branches
    // revisar video

    function testWithdrawCorrectly() public {
    
    }

    function testTwoWithdrawCorrectly() public {
    }

    function testWithdrawWithoutDeposit() public {
    }
    function testWithdrawWithoutEnoughtFunds() public {
    }
    function testWithdrawCorrectlyMoreThanMaxBalance() public {
    }

    // modify balance correcte
    // Sol ho pot fer l'admin

    function testChangeMaxBalanceCorrectly() public {
    }
    function testJustAdminCanChangeMaxBalance() public {
    }

    function testStakingTokenMintsCorrectly() public {
        vm.startPrank(randomUser);
        uint256 amount_ = 1 ether; 

        // Token balance previous
        uint256 balanceBefore_ = IERC20(address(stakingToken)).balanceOf(randomUser); // UserA = 50 tokens
        stakingToken.mint(amount_); // Mint 1 token
        // Token balance after
        uint256 balanceAfter_ = IERC20(address(stakingToken)).balanceOf(randomUser); // UserA = 51 tokens
        
        assert(balanceAfter_ - balanceBefore_ == amount_); // 51 tokens - 50 tokens == 1 token?

        vm.stopPrank();
    }
    */
}

// mas textos o quito alguno
// estan ben fets?