// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-v3/utils/Context.sol";
import "@openzeppelin/contracts-v3/access/Ownable.sol";
import "@openzeppelin/contracts-v3/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-v3/math/SafeMath.sol";
import "@openzeppelin/contracts-v3/utils/Address.sol";
import "@openzeppelin/contracts-v3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-v3/utils/EnumerableSet.sol";

// Extension of IERC20 interface to include additional functions
interface IExtendedERC20 is IERC20 {
    function getMaxSupply() external view returns (uint256);

    function mint(address _to, uint256 _amount) external returns (bool);
}

/**
 * @title xAQUAToken
 * @dev Implementation of an escrowed token that is linked to another ERC20 token
 */
contract xAQUAToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public maxSupply;

    EnumerableSet.AddressSet private _minters;
    EnumerableSet.AddressSet private _transferWhitelist;
    IExtendedERC20 public AQUA;

    /**
     * @dev Initializes the contract with the linked main token
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _aqua Address of the main token
     */
    constructor(
        string memory _name,
        string memory _symbol,
        IExtendedERC20 _aqua
    ) public ERC20(_name, _symbol) {
        require(
            address(_aqua) != address(0),
            "xAQUA: AQUA token cannot be the zero address"
        );
        AQUA = _aqua;
        maxSupply = AQUA.getMaxSupply(); // Set maxSupply to match the linked token's maxSupply
    }

    /**
     * @dev Override _mint to respect maxSupply
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(
            totalSupply().add(amount) <= maxSupply,
            "xAQUA: mint amount exceeds max supply"
        );
        super._mint(account, amount);
    }

    /**
     * @dev Creates `_amount` tokens and assigns them to `_to`.
     * First requests the main token to mint tokens for this contract.
     */
    function mint(
        address _to,
        uint256 _amount
    ) public onlyMinter returns (bool) {
        AQUA.mint(address(this), _amount);
        _mint(_to, _amount);
        return true;
    }

    /**
     * @dev Locks main tokens and mints escrowed tokens
     * @param _amount Amount of tokens to lock
     */
    function lock(uint256 _amount) public onlyMinter {
        require(
            AQUA.transferFrom(msg.sender, address(this), _amount),
            "xAQUA: AQUA token transfer failed"
        );
        _mint(msg.sender, _amount);
    }

    /**
     * @dev Redeems escrowed tokens for main tokens
     * @param _amount Amount of tokens to redeem
     */
    function redeem(uint256 _amount) public onlyMinter {
        require(
            AQUA.transfer(msg.sender, _amount),
            "xAQUA: AQUA token transfer failed"
        );
        _burn(msg.sender, _amount);
    }

    /**
     * @dev Burns tokens from an account if the caller has allowance
     * Only authorized minters can call this function
     */
    function burnFrom(address account, uint256 amount) external onlyMinter {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "xAQUA: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), currentAllowance.sub(amount));
        _burn(account, amount);
    }

    /**
     * @dev Adds an address to the list of authorized minters
     */
    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(
            _addMinter != address(0),
            "xAQUA: _addMinter is the zero address"
        );
        return EnumerableSet.add(_minters, _addMinter);
    }

    /**
     * @dev Removes an address from the list of authorized minters
     */
    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(
            _delMinter != address(0),
            "xAQUA: _delMinter is the zero address"
        );
        return EnumerableSet.remove(_minters, _delMinter);
    }

    /**
     * @dev Returns the number of minters
     */
    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    /**
     * @dev Checks if an address is an authorized minter
     */
    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    /**
     * @dev Returns the minter at the specified index
     */
    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "xAQUA: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    /**
     * @dev Modifier to restrict function access to authorized minters
     */
    modifier onlyMinter() {
        require(
            isMinter(msg.sender),
            "xAQUA: caller is not an authorized minter"
        );
        _;
    }

    /**
     * @dev Adds an address to the transfer whitelist
     * @param _address Address to add to the whitelist
     */
    function addToTransferWhitelist(
        address _address
    ) public onlyOwner returns (bool) {
        require(_address != address(0), "xAQUA: address is the zero address");
        return EnumerableSet.add(_transferWhitelist, _address);
    }

    /**
     * @dev Removes an address from the transfer whitelist
     * @param _address Address to remove from the whitelist
     */
    function removeFromTransferWhitelist(
        address _address
    ) public onlyOwner returns (bool) {
        require(_address != address(0), "xAQUA: address is the zero address");
        return EnumerableSet.remove(_transferWhitelist, _address);
    }

    /**
     * @dev Returns the number of addresses in the transfer whitelist
     */
    function getTransferWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_transferWhitelist);
    }

    /**
     * @dev Checks if an address is in the transfer whitelist
     * @param _address Address to check
     */
    function isInTransferWhitelist(
        address _address
    ) public view returns (bool) {
        return EnumerableSet.contains(_transferWhitelist, _address);
    }

    /**
     * @dev Returns the address at the specified index in the transfer whitelist
     * @param _index Index in the whitelist
     */
    function getTransferWhitelistAddress(
        uint256 _index
    ) public view onlyOwner returns (address) {
        require(
            _index <= getTransferWhitelistLength() - 1,
            "xAQUA: index out of bounds"
        );
        return EnumerableSet.at(_transferWhitelist, _index);
    }

    /**
     * @dev Hook that is called before any transfer of tokens
     * Ensures that either the sender or the recipient is in the transfer whitelist
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Skip the check for minting and burning operations
        if (from != address(0) && to != address(0)) {
            require(
                isInTransferWhitelist(from) || isInTransferWhitelist(to),
                "xAQUA: transfer not allowed, neither sender nor recipient is whitelisted"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
