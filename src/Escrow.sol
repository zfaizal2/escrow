// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    enum EscrowStatus {
        PENDING,
        SETTLED,
        CANCELLED
    }

    struct EscrowAccount {
        address payer;
        address recipient;
        uint256 amount;
        bool settled;
        address token;
        uint256 createdAt;
        EscrowStatus status;
    }

    mapping(uint256 => EscrowAccount) public escrowAccounts;
    uint256 public expiryTime = 30 days;

    function sanityCheck() public payable {
        sendToken(address(0), msg.sender, address(this), 1 ether);
    }

    function createEscrowAccount(uint256 id, address payer, address recipient, uint256 amount, address token)
        public
        payable
    {
        require(payer != recipient, "Payer and recipient cannot be the same");
        require(amount > 0, "Amount must be greater than 0");
        sendToken(token, payer, address(this), amount);
        escrowAccounts[id] =
            EscrowAccount(payer, recipient, amount, false, token, block.timestamp, EscrowStatus.PENDING);
    }

    function settleEscrowAccount(uint256 id) public {
        require(escrowAccounts[id].status == EscrowStatus.PENDING, "Escrow account is not pending");
        require(block.timestamp < escrowAccounts[id].createdAt + expiryTime, "Escrow account is expired");
        escrowAccounts[id].status = EscrowStatus.SETTLED;
        escrowAccounts[id].settled = true;
        sendToken(escrowAccounts[id].token, address(this), escrowAccounts[id].recipient, escrowAccounts[id].amount);
    }

    function cancelEscrowAccount(uint256 id) public {
        require(escrowAccounts[id].status == EscrowStatus.PENDING, "Escrow account is not pending");
        require(block.timestamp > escrowAccounts[id].createdAt + expiryTime, "Escrow account is still active");
        escrowAccounts[id].status = EscrowStatus.CANCELLED;
        escrowAccounts[id].settled = true;
        sendToken(escrowAccounts[id].token, address(this), escrowAccounts[id].payer, escrowAccounts[id].amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

function sendToken(address token, address sender, address recipient, uint256 amount) {
    if (token == address(0)) {
        payable(recipient).transfer(amount);
        (bool _sent, bytes memory _data) = recipient.call{value: amount}("");
    } else {
        IERC20(token).transferFrom(sender, recipient, amount);
    }
}
