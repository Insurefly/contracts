// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * @title WingToken
 * @notice This contract represents the WingToken (WING) ERC20 token with pausability and owner management.
 * @dev The contract allows for standard ERC20 functionality, along with pausability controlled by the owner.
 */
contract WingToken is ERC20, Pausable, ConfirmedOwner {
    constructor() ERC20("WingToken", "WING") ConfirmedOwner(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    modifier onlyWhenNotPaused() {
        require(!paused(), "WingToken: paused");
        _;
    }

    /**
     * @notice Mints new WING tokens to the specified address
     * @dev This function is only callable by the owner
     * @param account The address to receive the minted tokens
     * @param amount The number of tokens to mint
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @notice Pauses the contract, locking all minting and transferring of tokens
     * @dev This function can only be called by the owner
     */
    function pause() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, restoring minting and transferring of tokens
     * @dev This function can only be called by the owner
     */
    function unpause() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Transfers tokens from one address to another
     * @dev The transfer will fail if the contract is paused
     * @param recipient The address to receive the tokens
     * @param amount The number of tokens to transfer
     * @return success True if the transfer is successful
     */
    function transfer(address recipient, uint256 amount) public override onlyWhenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @notice Transfers tokens from one address to another on behalf of the sender
     * @dev The transfer will fail if the contract is paused
     * @param sender The address sending the tokens
     * @param recipient The address to receive the tokens
     * @param amount The number of tokens to transfer
     * @return success True if the transfer is successful
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        onlyWhenNotPaused
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @notice Gets the total supply of WING tokens
     * @return The total supply of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @notice Gets the balance of tokens for a given address
     * @param account The address to query the balance of
     * @return The balance of the specified address
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }
}
