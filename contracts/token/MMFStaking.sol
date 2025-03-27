// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts-v3/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-v3/math/SafeMath.sol";

interface IExtendedERC20 is IERC20 {
    function lock(uint256 _amount) external;

    function redeem(uint256 _amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract MMFStaking {
    using SafeMath for uint256;

    struct LockInfo {
        uint256 amount;
        uint256 prevReward;
        uint256 unlockTime;
        uint256 day;
        uint256 rewardAmount;
    }

    mapping(address => LockInfo[]) public userLock;

    uint256 minRedeemDays = 15;
    uint256 maxRedeemDays = 90;
    uint256 minRedeemDuration = minRedeemDays * 1 days;
    uint256 maxRedeemDuration = maxRedeemDays * 1 days;
    uint256 minRedeemRatio = 50;
    uint256 maxRedeemRatio = 100;

    IExtendedERC20 private token;
    IExtendedERC20 private escrowToken;

    constructor(IExtendedERC20 _token, IExtendedERC20 _escrowToken) {
        token = _token;
        escrowToken = _escrowToken;
    }

    function lock(uint256 _amount) public {
        require(token.transferFrom(msg.sender, address(this), _amount));
        token.approve(address(escrowToken), _amount);
        escrowToken.lock(_amount);
        escrowToken.transfer(msg.sender, _amount);
    }

    function initializeRedeem(uint256 _amount, uint256 _days) public {
        require(
            _days >= minRedeemDays || _days <= maxRedeemDays,
            "Lock time not valid"
        );
        require(
            escrowToken.balanceOf(msg.sender) >= _amount,
            "insufficent balance"
        );
        escrowToken.transferFrom(msg.sender, address(this), _amount);
        uint256 unlockTime = block.timestamp + (_days * 1 days);

        uint256 ratio = getRedeemRatio(_days);
        uint256 rewardAmount = _amount.mul(ratio).div(100);

        LockInfo memory info = LockInfo(
            _amount,
            0,
            unlockTime,
            _days,
            rewardAmount
        );

        userLock[msg.sender].push(info);
    }

    function finalizeRedeem(uint256 index) public {
        require(index < userLock[msg.sender].length, "index not valid");
        LockInfo memory info = userLock[msg.sender][index];
        require(block.timestamp >= info.unlockTime, "lock time not expired");

        escrowToken.redeem(info.amount);

        uint256 MMFresidual = info.amount.sub(info.rewardAmount);

        if (MMFresidual > 0) {
            token.approve(address(this), MMFresidual);
            token.burnFrom(address(this), MMFresidual);
        }

        token.transfer(msg.sender, info.rewardAmount);

        _deleteRedeemEntry(index, msg.sender);
    }

    function getRedeemRatio(uint256 _days) public view returns (uint256) {
        if (_days >= maxRedeemDays) return maxRedeemRatio;
        else if (_days == minRedeemDays) return minRedeemRatio;

        return
            minRedeemRatio.add(
                (_days.sub(minRedeemDays))
                    .mul(maxRedeemRatio.sub(minRedeemRatio))
                    .div(maxRedeemDays.sub(minRedeemDays))
            );
    }

    function _deleteRedeemEntry(uint256 index, address user) internal {
        userLock[user][index] = userLock[user][userLock[user].length - 1];
        userLock[user].pop();
    }

    function getUserRedeemLength(address user) public view returns (uint256) {
        return userLock[user].length;
    }

    function getUserRedeem(
        address user,
        uint256 index
    )
        public
        view
        returns (uint256 amount, uint256 rewardAmount, uint256 endTime)
    {
        require(index < userLock[user].length, "index not valid");
        LockInfo memory info = userLock[user][index];
        amount = info.amount;
        endTime = info.unlockTime;
        rewardAmount = info.rewardAmount;
    }
}
