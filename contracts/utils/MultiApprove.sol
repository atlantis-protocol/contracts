// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MultiApprove {
    function batchApprove(
        address[] calldata tokens,
        address spender,
        uint256[] calldata amounts
    ) external {
        require(
            tokens.length == amounts.length,
            "Tokens and amounts length mismatch"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            // Esegue approve per conto di msg.sender
            require(
                IERC20(tokens[i]).approve(spender, amounts[i]),
                "Approval failed"
            );
        }
    }
}
