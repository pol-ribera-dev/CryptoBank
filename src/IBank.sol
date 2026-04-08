// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

/// @title Interface of Bank.sol
/// @author Pol Ribera Moreno
/// @notice Is a CryptoBank

interface IBank {

    /// @notice Allows a user withdraw ether.
    function withdrawEther(uint256 amount_) external;
}