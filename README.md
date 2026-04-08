# CryptoBank
A simple Solidity project that implements a decentralized banking system with support for shared accounts.

## Overview

This project includes a basic bank contract where users can deposit and withdraw Ether, along with a multi-user account contract that allows several users to manage a single shared balance.

The system is designed to demonstrate how contracts interact with each other and how msg.sender affects account ownership when using intermediary contracts.

## Contracts

### CryptoBank (Bank.sol)

The main contract acts as a minimal bank. It keeps track of user balances and allows deposits and withdraws.

Each user interacts with their own balance, and the contract ensures that withdraws cannot exceed available funds. Also there is a configurable maximum balance per account.

### IBank (IBank.sol)

A simple interface used to interact with the bank contract. It allows external contracts to call the withdraw function.

### MultiUser Account (MultiUserAccount.sol)

This contract represents a shared account controlled by multiple users. From the bank’s perspective, this contract is a single account, but internally it manages permissions for different addresses.

Users can deposit funds into the bank through this contract and withdraw funds from it. The contract forwards calls to the bank and redistributes withdrawn Ether to the user who initiated the request.

IMPORTANT, it needs the path of IBank and it has to be delpoyed after the Bank.sol