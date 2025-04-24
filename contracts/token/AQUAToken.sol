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
    function getOwner() external view returns (address);

    function getMaxSupply() external view returns (uint256);
}

// Meerkat token with Governance.
contract AQUAToken is ERC20, Ownable, IExtendedERC20 {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public preMineSupply;
    uint256 public maxSupply;

    EnumerableSet.AddressSet private _minters;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _preMineSupply,
        uint256 _maxSupply
    ) public ERC20(_name, _symbol) {
        require(
            _preMineSupply <= _maxSupply,
            "AQUA: preMineSupply must be <= maxSupply"
        );
        // Convert to wei (multiply by 10^18)
        preMineSupply = _preMineSupply * 1e18;
        maxSupply = _maxSupply * 1e18;
        _mint(_msgSender(), preMineSupply);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the maximum supply of tokens.
     */
    function getMaxSupply() external view override returns (uint256) {
        return maxSupply;
    }

    /// @notice Creates `_amount` token to `_to`.
    function mint(
        address _to,
        uint256 _amount
    ) public onlyMinter returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external onlyMinter {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "AQUA: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), currentAllowance.sub(amount));
        _burn(account, amount);
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(
            _addMinter != address(0),
            "AQUA: _addMinter is the zero address"
        );
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(
            _delMinter != address(0),
            "AQUA: _delMinter is the zero address"
        );
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinterLength() - 1, "AQUA: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "AQUA: caller is not an authorized minter"
        );
        _;
    }

    /**
     * @dev Override _mint to respect maxSupply
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(
            totalSupply().add(amount) <= maxSupply,
            "AQUA: mint amount exceeds max supply"
        );
        super._mint(account, amount);
    }
}
