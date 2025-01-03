// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Escrow {
    struct EscrowAccount {
        address payer;
        address recipient;
        uint256 amount;
        bool settled;
        address token;
    }

    mapping(uint256 => EscrowAccount) public escrowAccounts;

    function createEscrowAccount(
        uint256 id,
        address payer,
        address recipient,
        uint256 amount,
        address token
    ) public payable {
        require(payer != recipient, "Payer and recipient cannot be the same");
        require(amount > 0, "Amount must be greater than 0");
        escrowAccounts[id] = EscrowAccount(payer, recipient, amount, false, token);
    }g

    


}
