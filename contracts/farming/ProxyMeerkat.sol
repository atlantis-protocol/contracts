// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-v3-upgradeable/access/OwnableUpgradeable.sol";
import "./library/WhitelistUpgradeable.sol";

contract ProxyMeerkat is OwnableUpgradeable, WhitelistUpgradeable {
    using SafeBEP20 for IBEP20;

    IBEP20 private MMF;

    function initialize(address _mmfAddress) external initializer {
        __Ownable_init();
        MMF = IBEP20(_mmfAddress);
    }

    function safeMeerkatTransfer(
        address to,
        uint256 amount
    ) external onlyWhitelisted returns (uint256) {
        uint256 meerkatBal = MMF.balanceOf(address(this));
        if (amount > meerkatBal) {
            MMF.transfer(to, meerkatBal);
            return meerkatBal;
        } else {
            MMF.transfer(to, amount);
            return amount;
        }
    }

    function recoverToken(
        IBEP20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        require(address(_token) != address(MMF));
        _token.safeTransfer(_to, _amount);
    }
}
