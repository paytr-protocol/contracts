// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Paytr} from "../src/Paytr.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IComet {
    function supply(address asset, uint amount) external;
    function withdraw(address asset, uint amount) external;
    function baseToken() external view returns (address);
    function allow(address manager, bool isAllowed) external;
}

contract PaytrTest is Test {
    using SafeERC20 for IERC20;

    Paytr Paytr_Test;

    IERC20 comet = IERC20(0xF09F0369aB0a875254fB565E52226c88f10Bc839);
    IERC20 baseAsset = IERC20(IComet(0xF09F0369aB0a875254fB565E52226c88f10Bc839).baseToken());
    address baseAssetAddress = IComet(0xF09F0369aB0a875254fB565E52226c88f10Bc839).baseToken();
    IERC20 cometWrapper = IERC20(0x797D7126C35E0894Ba76043dA874095db4776035);

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    address dummyFeeAddress = address(0x4);
    address owner = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);

    bytes paymentReference1 = "0x494e56332d32343001";
    bytes paymentReference2 = "0x494e56332d32343002";
    bytes paymentReference3 = "0x494e56332d32343003";
    bytes paymentReference4 = "0x494e56332d32343004";
    bytes paymentReference5 = "0x494e56332d32343005";
    bytes paymentReference6 = "0x494e56332d32343006";
    bytes paymentReference7 = "0x494e56332d32343007";
    bytes paymentReference8 = "0x494e56332d32343008";
    bytes paymentReference9 = "0x494e56332d32343009";
    bytes paymentReference10 = "0x494e56332d32343010";
    bytes paymentReference11 = "0x494e56332d32343011";
    bytes paymentReference12 = "0x494e56332d32343012";
    bytes paymentReference13 = "0x494e56332d32343013";
    bytes paymentReference14 = "0x494e56332d32343014";
    bytes paymentReference15 = "0x494e56332d32343015";
    bytes paymentReference16 = "0x494e56332d32343016";

    bytes[] public payOutArray;

    event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint256 dueDate, uint256 feeAmount, bytes paymentReference);
    event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference, uint256 feeAmount);
    event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);
    event ContractParametersUpdatedEvent(uint16 feeModifier, uint256 minDueDateParameter, uint256 maxDueDateParameter, uint256 minAmount, uint256 maxAmount, uint8 maxPayoutArraySize);
    event setERC20FeeProxyEvent(address ERC20FeeProxyAddress);

    function getContractCometWrapperBalance() public view returns(uint256) {
        uint256 contractCometWrapperBalance = cometWrapper.balanceOf(address(Paytr_Test));
        return contractCometWrapperBalance;
    }

    function getContractBaseAssetBalance() public view returns(uint256) {
        uint256 contractBaseAssetBalance = baseAsset.balanceOf(address(Paytr_Test));
        return contractBaseAssetBalance;
    }

    function getAlicesBaseAssetBalance() public view returns(uint256) {
        uint256 alicesBaseAssetBalance = baseAsset.balanceOf(alice);
        return alicesBaseAssetBalance;
    }
    
    function getBobsBaseAssetBalance() public view returns(uint256) {
        uint256 bobsBaseAssetBalance = baseAsset.balanceOf(bob);
        return bobsBaseAssetBalance;
    }
    function getCharliesBaseAssetBalance() public view returns(uint256) {
        uint256 charliesBaseAssetBalance = baseAsset.balanceOf(charlie);
        return charliesBaseAssetBalance;
    }

    function setUp() public {
        Paytr_Test = new Paytr(
            0xF09F0369aB0a875254fB565E52226c88f10Bc839,
            0x797D7126C35E0894Ba76043dA874095db4776035,
            9000,
            7 days,
            365 days,
            10e6,
            100_000e6,
            15
        );

        //deal baseAsset
        deal(address(baseAsset), alice, 10_000e6);
        uint256 balanceAlice = baseAsset.balanceOf(alice);
        assertEq(balanceAlice, 10_000e6);
        deal(address(baseAsset), bob, 10_000e6);
        uint256 balanceBob = baseAsset.balanceOf(bob);
        assertEq(balanceBob, 10_000e6);
        deal(address(baseAsset), charlie, 10_000e6);
        uint256 balanceCharlie = baseAsset.balanceOf(charlie);
        assertEq(balanceCharlie, 10_000e6);

        //approve baseAsset to contract
        vm.startPrank(alice);
        baseAsset.approve(address(Paytr_Test), 2**256 - 1);
        vm.stopPrank();
        vm.startPrank(bob);
        baseAsset.approve(address(Paytr_Test), 2**256 - 1);
        vm.stopPrank();
        vm.startPrank(charlie);
        baseAsset.approve(address(Paytr_Test), 2**256 - 1);
        vm.stopPrank();
    }

    function testFail_zeroAmount() public {

        uint256 amountToPay = 0;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );

    }

    function testFail_amountTooLow() public { //the min. amount is specified in the contract parameters.

        uint256 amountToPay = 9e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_amountTooHigh() public { //the max. amount is specified in the contract parameters.

        uint256 amountToPay = 100_001e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_zeroPayeeAddress() public {

        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            address(0),
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_zeroFeeAddress() public {

        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            address(0),
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_paymentReferenceInUse() public {

        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );

        vm.prank(bob);
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            block.timestamp + 18 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_dueDateTooLow() public {

        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 1 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_dueDateTooHigh() public {

        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 450 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        
    }

    function testFail_payOutArrayTooSmall() public {
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function testFail_payOutArrayTooBig() public {
        payOutArray = [
            paymentReference1,
            paymentReference2,
            paymentReference3,
            paymentReference4,
            paymentReference5,
            paymentReference6,
            paymentReference7,
            paymentReference8,
            paymentReference9,
            paymentReference10,
            paymentReference11,
            paymentReference12,
            paymentReference13,
            paymentReference14,
            paymentReference15,
            paymentReference16            
        ];
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function testFail_noPrePayment() public {
        payOutArray = [paymentReference1]; //this reference hasn't been prepaid in this function, so it should not be able to redeem it

        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function testFail_notDue() public {
        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 20 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );

        vm.warp(block.timestamp + 15 days);

        payOutArray = [paymentReference1];

        Paytr_Test.payOutERC20Invoice(payOutArray);

    }

    function testFail_alreadyPaidOut() public {
        uint256 amountToPay = 1000e6;

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 20 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );

        vm.warp(block.timestamp + 21 days);

        payOutArray = [paymentReference1];

        Paytr_Test.payOutERC20Invoice(payOutArray);

        console2.log("Mapping amount:",Paytr_Test.getMapping(paymentReference1).amount);
        console2.log("Mapping feeAddress:",Paytr_Test.getMapping(paymentReference1).feeAddress);
        console2.log("Mapping payee:",Paytr_Test.getMapping(paymentReference1).payee);

        vm.warp(block.timestamp + 150 days);

        payOutArray = [paymentReference1];

        Paytr_Test.payOutERC20Invoice(payOutArray);

    }



}