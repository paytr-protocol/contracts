// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Paytr} from "../src/Paytr.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Paytr_Helpers} from "../helpers/Helper_config.sol";

interface IComet {
    function supply(address asset, uint amount) external;
    function withdraw(address asset, uint amount) external;
    function baseToken() external view returns (address);
    function allow(address manager, bool isAllowed) external;
}

contract PaytrTest is Test, Paytr_Helpers {
    using SafeERC20 for IERC20;

    function setUp() public {
        Paytr_Test = new Paytr(
            cometAddress,
            cometWrapperAddress,
            9000,
            7 days,
            365 days,
            10e6,
            15
        );

        vm.label(cometAddress, "Comet");
        vm.label(baseAssetAddress, "USDC");
        vm.label(cometWrapperAddress, "Wrapper Contract");
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(charlie, "charlie");
        vm.label(address(this), "Paytr");
        vm.label(ERC20FeeProxy, "ERC20FeeProxy contract");

        transferBaseAsset();
        approveBaseAsset();

        Paytr_Test.setERC20FeeProxy(ERC20FeeProxy);
    }

    function test_RevertIf_AmountIsZeroAndFeeIsZero() public {

        uint256 amountToPay = 0;

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );

    }

    function test_RevertIf_AmountIsZero() public {
        uint256 amountToPay = 0;
        
        vm.prank(alice);
        
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));        
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            1000 * (10 ** decimals),
            paymentReference1,
            false
        );
        }

    function test_RevertIf_MinimumAmountIsTooLow() public { //the min. amount is specified in the contract parameters.

        uint256 amountToPay = 9 * (10 ** decimals);

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("InvalidTotalAmount()"));        

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function test_RevertIf_PayeeAddressIsZeroAddress() public {

        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("ZeroPayeeAddress()"));
        Paytr_Test.payInvoiceERC20(
            address(0),
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function test_RevertIf_FeeAddressIsZeroAddress() public {

        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("ZeroFeeAddress()"));

        Paytr_Test.payInvoiceERC20(
            bob,
            address(0),
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function test_RevertIf_PaymentReferenceIsInUse() public {

        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );

        vm.prank(bob);

        vm.expectRevert(abi.encodeWithSignature("PaymentReferenceInUse()"));
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            uint40(block.timestamp + 18 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function test_revertIf_DueDateIsTooLow() public {

        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("DueDateNotAllowed()"));
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 1 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function test_revertIf_DueDateIsTooHigh() public {

        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSignature("DueDateNotAllowed()"));
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 450 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function test_RevertIf_PayOutArrayIsTooSmall() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidArrayLength()"));
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function test_RevertIf_PayOutArrayIsTooBig() public {
        uint256 amountToPay = 1000 * (10 ** decimals);     
        
        for (uint8 i = 0; i < 16; i++) {
            vm.prank(alice);
            bytes memory newPaymentReference = abi.encodePacked(i);
            payOutArray.push(newPaymentReference);
            Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 30 days),
            amountToPay,
            0,
            newPaymentReference,
            false
            );

        }
        
        vm.warp(block.timestamp + 33 days);
        vm.expectRevert(abi.encodeWithSignature("InvalidArrayLength()"));
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function test_RevertIf_InvoiceNotPrePaid() public {
        payOutArray = [paymentReference1]; //this reference hasn't been prepaid in this test, so it should not be able to redeem it
        
        vm.expectRevert(abi.encodeWithSignature("NoPrePayment()"));
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function test_RevertIf_InvoiceNotDue() public {
        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 20 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );

        vm.warp(block.timestamp + 15 days);

        payOutArray = [paymentReference1];

        vm.expectRevert(abi.encodeWithSignature("ReferenceNotDue()"));
        Paytr_Test.payOutERC20Invoice(payOutArray);

    }

    function test_RevertIf_InvoiceWasAlreadyPaidOut() public {
        uint256 amountToPay = 1000 * (10 ** decimals);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 20 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );

        vm.warp(block.timestamp + 21 days);
        payOutArray = [paymentReference1];
        Paytr_Test.payOutERC20Invoice(payOutArray);

        vm.warp(block.timestamp + 150 days);
        payOutArray = [paymentReference1];

        vm.expectRevert(abi.encodeWithSignature("NoPrePayment()"));
        Paytr_Test.payOutERC20Invoice(payOutArray);

    }

    function test_RevertIf_ClaimCompRewardsNotOwner() public {
        vm.prank(bob);

        vm.expectRevert("Ownable: caller is not the owner");
        Paytr_Test.claimCompRewards();
    }

    function test_RevertIf_ChangeParametersNotOwner() public {
        vm.prank(alice);

        vm.expectRevert("Ownable: caller is not the owner");
        Paytr_Test.setContractParameters(
            8000,
            20 days,
            365 days,
            100e6,
            60
        );
    }

    function test_RevertIf_ChangeParametersWithInvalidContractFeeModifier() public {
        vm.prank(owner);
            
        vm.expectRevert(abi.encodeWithSignature("InvalidContractFeeModifier()"));
        Paytr_Test.setContractParameters(
            1,
            20 days,
            365 days,
            100e6,
            60
        );
    }

    function test_RevertIf_ChangeParametersWithInvalidMinDueDate() public {
        vm.prank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidMinDueDate()"));
        Paytr_Test.setContractParameters(
            8000,
            1 days,
            365 days,
            100e6,
            60
        );
    }

    function test_RevertIf_ChangeParametersWithInvalidMaxDueDate() public {
        vm.prank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidMaxDueDate()"));
        Paytr_Test.setContractParameters(
            8000,
            20 days,
            5000 days,
            100e6,
            60
        );
    }

    function test_RevertIf_ChangeParametersWithInvalidMinAmount() public {
        vm.prank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidMinAmount()"));
        Paytr_Test.setContractParameters(
            8000,
            20 days,
            365 days,
            0,
            60
        );
    }

    //Paytr.sol doesn't check the maxAmount parameter, no test needed

    function test_RevertIf_ChangeParametersWithInvalidMaxPayOutArraySize() public {
        vm.prank(owner);

        vm.expectRevert(abi.encodeWithSignature("InvalidMaxArraySize()"));
        Paytr_Test.setContractParameters(
            8000,
            20 days,
            365 days,
            100e6,
            0
        );
    }

}