// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FundsManager is ReentrancyGuard, Ownable {
    /* errors */
    error FundsManager__InsufficientBalance();
    error FundsManager__TransferFailed();

    /* State variables */
    uint256 private s_totalFunds;

    /* Events */
    event FundsReceived(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event ClaimPaid(address indexed to, uint256 amount);

    /* constructor */
    constructor() Ownable(msg.sender) {}

    /* receive function */
    receive() external payable {
        s_totalFunds += msg.value;
        emit FundsReceived(msg.sender, msg.value);
    }

    /* fallback function */
    fallback() external payable {
        s_totalFunds += msg.value;
        emit FundsReceived(msg.sender, msg.value);
    }

    /* external */
    function depositPremium(address user) external payable {
        // s_userBalances[user] += msg.value;
        s_totalFunds += msg.value;
        emit FundsReceived(user, msg.value);
    }

    function withdrawFunds(uint256 amount) external onlyOwner nonReentrant {
        if (amount > s_totalFunds) {
            revert FundsManager__InsufficientBalance();
        }

        s_totalFunds -= amount;
        (bool success,) = owner().call{value: amount}("");
        if (!success) {
            revert FundsManager__TransferFailed();
        }

        emit FundsWithdrawn(owner(), amount);
    }

    function payClaim(address user, uint256 amount) external onlyOwner nonReentrant {
        if (amount > s_totalFunds) {
            revert FundsManager__InsufficientBalance();
        }

        s_totalFunds -= amount;
        (bool success,) = user.call{value: amount}("");
        if (!success) {
            revert FundsManager__TransferFailed();
        }

        emit ClaimPaid(user, amount);
    }

    function addFunds() external payable onlyOwner {
        s_totalFunds += msg.value;
        emit FundsReceived(msg.sender, msg.value);
    }

    /* external view functions */

    function getTotalFunds() external view returns (uint256) {
        return s_totalFunds;
    }

    /* public */
    /* internal */
    /* private */
    /* internal & private view & pure functions */
    /* external & public view & pure functions */
}
