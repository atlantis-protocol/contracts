// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-v4/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-v4/access/Ownable.sol";

/**
 * @title EscrowedToken
 * @dev Implementation of an escrowed token that is linked to another ERC20 token
 * This token allows locking the linked token and minting escrowed tokens, and vice versa
 */
contract EscrowedToken is ERC20, Ownable {
    // The linked token that this escrowed token represents
    ERC20 private immutable _linkedToken;

    // Set of addresses that are allowed to mint tokens
    mapping(address => bool) private _minters;

    // Events
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event TokensLocked(address indexed user, uint256 amount);
    event TokensRedeemed(address indexed user, uint256 amount);

    /**
     * @dev Initializes the contract setting name, symbol, and the linked token
     * @param name Token name
     * @param symbol Token symbol
     * @param linkedToken The ERC20 token that this escrowed token is linked to
     */
    constructor(
        string memory name,
        string memory symbol,
        ERC20 linkedToken
    ) ERC20(name, symbol) Ownable() {
        require(
            address(linkedToken) != address(0),
            "Linked token cannot be the zero address"
        );
        _linkedToken = linkedToken;
    }

    /**
     * @dev Returns the linked token address
     */
    function getLinkedToken() public view returns (address) {
        return address(_linkedToken);
    }

    /**
     * @dev Locks linked tokens and mints escrowed tokens
     * @param amount Amount of tokens to lock
     */
    function lock(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");

        // Transfer linked tokens from sender to this contract
        require(
            _linkedToken.transferFrom(msg.sender, address(this), amount),
            "Transfer of linked tokens failed"
        );

        // Mint escrowed tokens to sender
        _mint(msg.sender, amount);

        emit TokensLocked(msg.sender, amount);
    }

    /**
     * @dev Redeems escrowed tokens for linked tokens
     * @param amount Amount of tokens to redeem
     */
    function redeem(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Burn escrowed tokens from sender
        _burn(msg.sender, amount);

        // Transfer linked tokens to sender
        require(
            _linkedToken.transfer(msg.sender, amount),
            "Transfer of linked tokens failed"
        );

        emit TokensRedeemed(msg.sender, amount);
    }

    /**
     * @dev Burns tokens from an account if the caller has allowance
     * Can only be called by authorized minters
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external onlyMinter {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    /**
     * @dev Adds an address to the list of authorized minters
     * Can only be called by the contract owner
     * @param minter Address to add as a minter
     */
    function addMinter(address minter) public onlyOwner returns (bool) {
        require(minter != address(0), "Minter cannot be the zero address");
        require(!_minters[minter], "Address is already a minter");

        _minters[minter] = true;
        emit MinterAdded(minter);
        return true;
    }

    /**
     * @dev Removes an address from the list of authorized minters
     * Can only be called by the contract owner
     * @param minter Address to remove as a minter
     */
    function removeMinter(address minter) public onlyOwner returns (bool) {
        require(minter != address(0), "Minter cannot be the zero address");
        require(_minters[minter], "Address is not a minter");

        _minters[minter] = false;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev Checks if an address is an authorized minter
     * @param account Address to check
     */
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    /**
     * @dev Modifier to restrict function access to authorized minters
     */
    modifier onlyMinter() {
        require(
            _minters[msg.sender] || msg.sender == owner(),
            "Caller is not a minter or owner"
        );
        _;
    }
}
