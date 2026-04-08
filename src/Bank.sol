// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;


/*  
    @title CryptoBank

    @notice This is a simple contract that simulates a bank; it stores the Ether balance of users and allows them to deposit and withdraw. 
    
    @dev We have to support different users, so everyone can only modify their own account. When someone wants to deposit Ether, the contract has to check the 
    maxBalance limit (which can be modified by the owner). Also, users can only withdraw previously deposited Ether. Additionally, users should be able to perform 
    infinite actions, so the contract has to keep track of the state at all times. 
*/

contract CryptoBank {


    // VARIABLES

    /// @dev Relationates every address with a balance.
    mapping(address => uint256) public userBalance;

    /// @dev Max amout an accound can afford
    uint256 public maxBalance;

    /// @dev The address of the admin
    address public admin;
    

    // CONSTRUCTOR

    /// @dev Sets the initial maxBalance and the admin
    /// @param maxBalance_ The maximum amount that an account can afford 
    /// @param admin_ The address of the admin
    constructor(uint256 maxBalance_, address admin_) {
        maxBalance = maxBalance_;
        admin = admin_;
    }
    

    // MODIFIERS

    /// @notice Checks if the address that calls the function is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not allowed");
        _;
    }


    // EVENTS

    /// @notice Emitted when someone do a deposit
    /// @param user_ Is the owner of the account
    /// @param etheramount_ Is the amount of ether being deposited
    event EtherDeposit(address user_, uint256 etheramount_);

    /// @notice Emitted when someone withdraw etherium
    /// @param user_ Is the owner of the account
    /// @param etheramount_ Is the amount of ether being withdrawed
    event EtherWithdraw(address user_, uint256 etheramount_);

    

    // EXTERNAL FUNCTIONS

    /// @notice Allows a user deposit ether.
    /// @dev Cheks that after the deposit the balance is less than the 'maxBalance' and then increments 
    /// the balance of that user by the amount of ether that he has sended.
    /// Emits {EtherDeposit} with the address of the user and the amount of the deposit.
    function depositEther() external payable {
        require(userBalance[msg.sender] + msg.value <= maxBalance, "MaxBalance reached");
        userBalance[msg.sender] += msg.value;
        emit EtherDeposit(msg.sender, msg.value);               
    }


    /// @notice Allows a user withdraw ether.
    /// @dev This function follows the CEI pattern to avoid reentrancy attacks. First checks that the amount
    /// of ether that the user wants to withdraw is equal or lower that the amount of ether he has in the account. 
    /// Then the contract substracts it from his balance and sends that amount to the user. 
    /// @param amount_ the amount of ether that user wants to withdraw.
    /// Emits {EtherWithdraw} with the address of the user and the amount of the withdraw.
    function withdrawEther(uint256 amount_) external {
        require(amount_ <= userBalance[msg.sender], "Not enough ether");                 
        userBalance[msg.sender] -= amount_;
        (bool success,) = msg.sender.call{value: amount_}(""); // RECEIVE
        require(success, "Transfer failed");
        emit EtherWithdraw(msg.sender, amount_);
    }

    /// @notice Allows the admin change the 'maxBalance'. Realise that if there are acounts with bigger amount than the new 
    /// 'maxBalance' they will not be instantly affected.
    /// @param newMaxBalance_ The new max balance.
    function modifyMaxBalance(uint256 newMaxBalance_) external onlyAdmin {
        maxBalance = newMaxBalance_; 
    }
}