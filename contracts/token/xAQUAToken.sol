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
    function maxSupply() external view returns (uint256);

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
    IExtendedERC20 public MMF;

    /**
     * @dev Initializes the contract with the linked main token
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _mmf Address of the main token
     */
    constructor(
        string memory _name,
        string memory _symbol,
        IExtendedERC20 _mmf
    ) public ERC20(_name, _symbol) {
        require(address(_mmf) != address(0), "MMF cannot be the zero address");
        MMF = _mmf;
        maxSupply = MMF.maxSupply(); // Set maxSupply to match the linked token's maxSupply
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
        MMF.mint(address(this), _amount);
        _mint(_to, _amount);
        return true;
    }

    /**
     * @dev Locks main tokens and mints escrowed tokens
     * @param _amount Amount of tokens to lock
     */
    function lock(uint256 _amount) public onlyMinter {
        require(
            MMF.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        _mint(msg.sender, _amount);
    }

    /**
     * @dev Redeems escrowed tokens for main tokens
     * @param _amount Amount of tokens to redeem
     */
    function redeem(uint256 _amount) public onlyMinter {
        require(MMF.transfer(msg.sender, _amount), "Transfer failed");
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
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }
}
