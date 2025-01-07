// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TEST") {}
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}


contract EscrowTest is Test {
    Escrow public escrow;
    TestToken public token;
    
    address public payer =  0xEBcFba9f74a34f7118D1D2C078fCff4719D6518D;
    address public recipient = 0x534347d1766E89dB52C440AF833f0384d861B13E;
    uint256 public defaultAmount = 5;
    uint256 public id = 1;
    uint public expiryTime = 31 days;

    function setUp() public {
        escrow = new Escrow();
        token = new TestToken();

        // Fund accounts
        vm.deal(payer, 10 ether);
        vm.deal(recipient, 0.1 ether);
    }

    function test_SanityCheck() public {
        vm.startPrank(payer);
        escrow.sanityCheck{value: 1 ether}();
        vm.stopPrank();
    }


    function test_CreateEscrowWithEth() public {
        vm.startPrank(payer);
        escrow.createEscrowAccount{value: defaultAmount}(id, payer, recipient, defaultAmount, address(0));
        vm.stopPrank();

        (address _payer, address _recipient, uint256 _amount, bool _settled, address _token, , ) = escrow.escrowAccounts(id);
        
        assertEq(_payer, payer);
        assertEq(_recipient, recipient);
        assertEq(_amount, defaultAmount);
        assertEq(_settled, false);
        assertEq(_token, address(0));
        assertEq(address(escrow).balance, defaultAmount);
    }

    function test_CreateEscrowWithERC20() public {
        token.mint(payer, 10);
        vm.startPrank(payer);
        token.approve(address(escrow), defaultAmount);
        escrow.createEscrowAccount(id, payer, recipient, defaultAmount, address(token));
        vm.stopPrank();

        (address _payer, address _recipient, uint256 _amount, bool _settled, address _token, , ) = escrow.escrowAccounts(id);
        
        assertEq(_payer, payer);
        assertEq(_recipient, recipient);
        assertEq(_amount, defaultAmount);
        assertEq(_settled, false);
        assertEq(_token, address(token));
        assertEq(token.balanceOf(address(escrow)), defaultAmount);
    }

    function test_SettleEscrowWithEth() public {
        // Create escrow first
        vm.startPrank(payer);
        escrow.createEscrowAccount{value: defaultAmount}(id, payer, recipient, defaultAmount, address(0));
        vm.stopPrank();

        uint256 recipientBalanceBefore = recipient.balance;
        
        // Settle escrow
        escrow.settleEscrowAccount(id);
        
        (, , , bool _settled, , , Escrow.EscrowStatus _status) = escrow.escrowAccounts(id);
        assertEq(_settled, true);
        assertEq(uint256(_status), uint256(Escrow.EscrowStatus.SETTLED));
        assertEq(recipient.balance - recipientBalanceBefore, defaultAmount);
    }

    function test_CancelEscrowWithEth() public {
        // Create escrow first
        vm.startPrank(payer);
        escrow.createEscrowAccount{value: defaultAmount}(id, payer, recipient, defaultAmount, address(0));
        vm.stopPrank();

        // Warp time to after 30 days
        vm.warp(block.timestamp + expiryTime);

        uint256 payerBalanceBefore = payer.balance;
        
        // Cancel escrow
        escrow.cancelEscrowAccount(id);
        
        (, , , bool _settled, , , Escrow.EscrowStatus _status) = escrow.escrowAccounts(id);
        assertEq(_settled, true);
        assertEq(uint256(_status), uint256(Escrow.EscrowStatus.CANCELLED));
        assertEq(payer.balance - payerBalanceBefore, defaultAmount);
    }

    function test_CancelEscrowWithEthAsRecipient() public {
        // Create escrow first
        vm.startPrank(payer);
        escrow.createEscrowAccount{value: defaultAmount}(id, payer, recipient, defaultAmount, address(0));
        vm.stopPrank();


        // Warp time to after 30 days
        vm.warp(block.timestamp + expiryTime);

        uint256 payerBalanceBefore = payer.balance;

        // Set signer as recipient
        vm.startPrank(recipient);
        escrow.cancelEscrowAccount(id);
        vm.stopPrank();

        (, , , bool _settled, , , Escrow.EscrowStatus _status) = escrow.escrowAccounts(id);
        assertEq(_settled, true);
        assertEq(uint256(_status), uint256(Escrow.EscrowStatus.CANCELLED));
        assertEq(payer.balance - payerBalanceBefore, defaultAmount);
    }

    function testRevert_SettleExpiredEscrow() public {
        // Create escrow first
        vm.startPrank(payer);
        escrow.createEscrowAccount{value: defaultAmount}(id, payer, recipient, defaultAmount, address(0));
        vm.stopPrank();

        // Warp time to after 30 days
        vm.warp(block.timestamp + expiryTime);

        vm.expectRevert("Escrow account is expired");
        escrow.settleEscrowAccount(id);
    }

    function testRevert_CancelActiveEscrow() public {
        // Create escrow first
        vm.startPrank(payer);
        escrow.createEscrowAccount{value: defaultAmount}(id, payer, recipient, defaultAmount, address(0));
        vm.stopPrank();

        vm.expectRevert("Escrow account is still active");
        escrow.cancelEscrowAccount(id);
    }

    function test_Fuzz_CreateEscrowWithEth(uint256 amount) public {
        if (amount > 0) {
            vm.deal(payer, amount);
        }
        vm.startPrank(payer);
        if (amount <= 0) {
            vm.expectRevert("Amount must be greater than 0");
        }
        escrow.createEscrowAccount{value: amount}(id, payer, recipient, amount, address(0));
        vm.stopPrank();
        if (amount > 0) {
            (address _payer, address _recipient, uint256 _amount, bool _settled, address _token, , ) = escrow.escrowAccounts(id);

            assertEq(_payer, payer);
            assertEq(_recipient, recipient);
            assertEq(_amount, amount);
            assertEq(_settled, false);
            assertEq(_token, address(0));
            assertEq(address(escrow).balance, amount);
        }
    }

    function test_CreateEscrowWithERC20(uint256 amount) public {
        if (amount > 0) {
            token.mint(payer, amount);
        }
        vm.startPrank(payer);
        token.approve(address(escrow), amount);
        if (amount <= 0) {
            vm.expectRevert("Amount must be greater than 0");
        }
        escrow.createEscrowAccount(id, payer, recipient, amount, address(token));
        vm.stopPrank();
        if (amount > 0) {
            (address _payer, address _recipient, uint256 _amount, bool _settled, address _token, , ) = escrow.escrowAccounts(id);
        
            assertEq(_payer, payer);
            assertEq(_recipient, recipient);
            assertEq(_amount, amount);
            assertEq(_settled, false);
            assertEq(_token, address(token));
            assertEq(token.balanceOf(address(escrow)), amount);
        }
    }
}
