// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-v4/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-v4/access/Ownable.sol";

/**
 * @title StandardToken
 * @dev Implementation of the StandardToken
 * A standard ERC20 token with minting capabilities and supply limits
 */
contract StandardToken is ERC20, Ownable {
    uint256 private immutable _maxSupply;

    /**
     * @dev Initializes the contract setting name, symbol, maxSupply and initialSupply
     * @param name Token name
     * @param symbol Token symbol
     * @param maxSupplyValue Maximum token supply
     * @param initialSupply Initial token supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupplyValue,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable() {
        require(
            maxSupplyValue >= initialSupply,
            "Max supply must be greater than or equal to initial supply"
        );
        require(initialSupply > 0, "Initial supply must be greater than zero");

        _maxSupply = maxSupplyValue;

        // Mint initial supply to contract creator
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Returns the maximum supply of the token
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Creates new tokens and assigns them to the specified address
     * Can only be called by the contract owner
     * @param to Address to receive the new tokens
     * @param amount Amount of tokens to create
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= _maxSupply, "Exceeds maximum supply");
        _mint(to, amount);
    }
}
