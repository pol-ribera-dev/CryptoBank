// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "./IBank.sol";

/*  
    @title MultiUser

    @author Pol Ribera Moreno

    @notice This contract represents a shared account to be used in a bank (in this case the Bank.sol), basicaly acts like a user 
    infront the bank but the reality is that it is managed by several users that can deploy or withdraw that accound. An example of case of 
    use is a family account. The contract doesn't store money, just is a interceptor. In this case the power distribution is horizontal all 
    the allowed users have the same privileges.
    
    This is the base contract but then here we can program some interesting features (like no one can 
    withdraw in total more than 50% of the maximum) or some new roles (for example parents that can't withdraw, but kids can).
    
    @dev This contract is possible because the bank uses msg.sender insted of tx.origin, because then the address of this contract
    has his own balance and can be interpreted as a user. 
    
    Functions of allowed users:
    - Deploy ether
    - Withdraw ether
    - invite user
    - delete user

    @custom:dev If we want to use the contract with a diferent bank, we just need to change the interface, the name of the fuunction 
    it calls and put the address correctly when it is deployed. Obiously it will not work if the bank has some feature that breaks all,
    so be carefull!

*/

contract MultiUser {


    // VARIABLES

    /// @dev Relationates every address with if they are allowed or not. At the start the only allowed is the deployer. 
    mapping(address => bool) public userAllowed; 
    
    /// @dev The address of the bank the contract interacts with.
    address bank;


    // CONSTRUCTOR

    /// @dev Sets the bank address and give permision to the user that deploys the contract.
    /// @param bankAddress_ The address of the bank the contract interacts with.
    constructor(address bankAddress_) {
            bank = bankAddress_;
            userAllowed[msg.sender] = true; 
    }


    // MODIFIERS

    /// @notice Checks if the address that calls the function is allowed
    modifier onlyAllowed() {
        require( userAllowed[msg.sender], "Not allowed");
        _;
    }


    // EXTERNAL FUNCTIONS
    
    /// @notice function to receive money from the bank.
    receive() external payable {}


    /// @notice Lets an allowed user to deposit ether in the MultiAcount.
    /// @dev Calls the 'depositEther()' function of the bank with the ether we just send to this contract.
    function depositEther() external onlyAllowed payable {
        IBank(bank).depositEther{value: msg.value}();
    }

    /// @notice Lets an allowed user to withdraw ether from the MultiAcount.
    /// @dev Use the IBank interface to call the 'withdrawEther()' function of the bank with the parameter amount_. That 
    /// generates a call from the bank to this contract with the amount of ether that we ask for, so the receive function
    /// will take the money and finally there is a call to the sender with that money.
    /// @param amount_ The amount of ether to withdraw.
    function withdrawEther(uint256 amount_) onlyAllowed external {
        IBank(bank).withdrawEther(amount_);
        (bool success,) = msg.sender.call{value: amount_}("");
        require(success, "Withdraw failed");
    }

    /// @notice Lets a allowed user to give allowance to another user.
    /// @dev Change the boolean value of 'newUser_' the mapping to true
    /// @param newUser_ The address of the new user to be allowed.
    function invitation(address newUser_) external onlyAllowed {
        userAllowed[newUser_] = true; 
    }
    
    /// @notice Lets a allowed user to remove the allowance of a user.
    /// @dev Change the boolean value of 'eliminatedUser_' the mapping to false
    /// @param eliminatedUser_ The address of the new user to be disallowed.
    function elimination(address eliminatedUser_) external onlyAllowed {
        userAllowed[eliminatedUser_] = false; 
    }

}


