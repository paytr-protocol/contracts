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

    uint256 amountToPay = 1000e6;

    bytes paymentReference1 = "0x494e56332d32343001";
    bytes paymentReference2 = "0x494e56332d32343002";
    bytes paymentReference3 = "0x494e56332d32343003";

    bytes[] public payOutArray;

    event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint256 dueDate, uint256 feeAmount, bytes paymentReference);
    event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference, uint256 feeAmount);
    event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);

    function getContractCometWrapperBalance() public view returns(uint256) {
    uint256 contractCometWrapperBalance = cometWrapper.balanceOf(address(Paytr_Test));
    return contractCometWrapperBalance;
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
            30
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

    function test_payInvoiceERC20Single() public {

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, block.timestamp + 10 days, 0, "0x494e56332d32343001");

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
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 10000e6 - amountToPay);
        assertEq(getBobsBaseAssetBalance(), 10000e6);
        assertEq(getCharliesBaseAssetBalance(), 10000e6);
        assertEq(baseAsset.balanceOf(dummyFeeAddress), 0);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(dummyFeeAddress), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(getContractCometWrapperBalance(), amountToPay, 0.1e18);

    }

    function test_payInvoiceERC20Double() public {

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        assert(baseAsset.allowance(bob, address(Paytr_Test)) > 1000e6);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, block.timestamp + 10 days, 0, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference1,
            false
        );
        vm.stopPrank();

        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 10000e6 - amountToPay);
        assertEq(getBobsBaseAssetBalance(), 10000e6);
        assertEq(getCharliesBaseAssetBalance(), 10000e6);
        assertEq(baseAsset.balanceOf(dummyFeeAddress), 0);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);
        
        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(dummyFeeAddress), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(getContractCometWrapperBalance(), amountToPay, 0.1e18);

        uint256 contractCometWrapperBalanceBeforeSecondPayment = getContractCometWrapperBalance();

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, charlie, dummyFeeAddress, amountToPay, block.timestamp + 10 days, 0, paymentReference2);

        vm.startPrank(bob);
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            block.timestamp + 10 days,
            amountToPay,
            0,
            paymentReference2,
            false       
        );
        vm.stopPrank();

        uint256 contractCometWrapperBalanceAfterSecondPayment = getContractCometWrapperBalance();

        //baseAsset balances
        assertEq(getBobsBaseAssetBalance(), 10000e6 - amountToPay);
        assertEq(getCharliesBaseAssetBalance(), 10000e6);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);          
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(contractCometWrapperBalanceAfterSecondPayment, contractCometWrapperBalanceBeforeSecondPayment + amountToPay, 0.1e18);

    }

    function test_payAndRedeemSingle() public {
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        test_payInvoiceERC20Single();

        vm.expectEmit(address(Paytr_Test));

        uint256 aliceBAseAssetBalanceBeforePayOut = getAlicesBaseAssetBalance();

        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).feeAddress,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            0
        ); 
        
        //increase time to gain interest
        vm.warp(block.timestamp + 120 days);

        //redeem
        payOutArray = [paymentReference1];
        Paytr_Test.payOutERC20Invoice(payOutArray);

        uint256 interestAmount = getAlicesBaseAssetBalance() - aliceBAseAssetBalanceBeforePayOut;
        uint256 expectedAlicesBaseAssetBalance = interestAmount + aliceBAseAssetBalanceBeforePayOut;
        uint256 contractBaseAssetBalance = baseAsset.balanceOf(address(Paytr_Test));

        emit InterestPayoutEvent(
            baseAssetAddress, 
            Paytr_Test.getMapping(paymentReference1).payee,
            interestAmount,
            paymentReference1
        );
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), expectedAlicesBaseAssetBalance); //alice receives interest after the payOutERC20Invoice has been called
        assertEq(getBobsBaseAssetBalance(), 10000e6 + amountToPay); //Bob's starting balance is 10000e6, and he is the payee of the invoice getting paid out
        assertEq(getCharliesBaseAssetBalance(), 10000e6);
        assert(baseAsset.balanceOf(address(Paytr_Test)) > 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertEq(contractBaseAssetBalance, ((interestAmount + contractBaseAssetBalance) * 1000 / 10000 + 1)); //+1 due to rounding differences

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);

        //cometWrapper (wcbaseAssetv3) balances
        assertEq(getContractCometWrapperBalance(), 0);

    }

    function test_payThreePayOutTwo() public {
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        assert(baseAsset.allowance(bob, address(Paytr_Test)) > 1000e6);
        assert(baseAsset.allowance(charlie, address(Paytr_Test)) > 1000e6);

        uint256 aliceBaseAssetBalanceBeforePayment = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceBeforePayment = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceBeforePayment = getCharliesBaseAssetBalance();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, block.timestamp + 10 days, 0, paymentReference1); //payer alice, payee bob

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
        vm.stopPrank();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, charlie, dummyFeeAddress, amountToPay, block.timestamp + 12 days, 0, paymentReference2); //payer bob, payee charlie

        vm.prank(bob);
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            block.timestamp + 12 days,
            amountToPay,
            0,
            paymentReference2,
            false
        );
        vm.stopPrank();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, alice, dummyFeeAddress, amountToPay, block.timestamp + 40 days, 0, paymentReference3); //payer charlie, payee alice

        vm.prank(charlie);
        Paytr_Test.payInvoiceERC20(
            alice,
            dummyFeeAddress,
            block.timestamp + 40 days,
            amountToPay,
            0,
            paymentReference3,
            false
        );
        vm.stopPrank();

        assertEq(getAlicesBaseAssetBalance(), aliceBaseAssetBalanceBeforePayment - amountToPay);
        assertEq(getBobsBaseAssetBalance(), bobBaseAssetBalanceBeforePayment - amountToPay);
        assertEq(getCharliesBaseAssetBalance(), charlieBaseAssetBalanceBeforePayment - amountToPay);

        uint256 aliceBaseAssetBalanceBeforePayOut = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceBeforePayOut = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceBeforePayOut = getCharliesBaseAssetBalance();
        uint256 contractBaseAssetBalanceBeforePayOut = baseAsset.balanceOf(address(Paytr_Test));

        vm.expectEmit(address(Paytr_Test));
        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).feeAddress,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            0
        );

        vm.expectEmit(address(Paytr_Test));
        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference2).payee,
            Paytr_Test.getMapping(paymentReference2).feeAddress,
            Paytr_Test.getMapping(paymentReference2).amount,
            paymentReference2,
            0
        ); 

        //increase time to gain interest
        vm.warp(block.timestamp + 60 days);
    
        //redeem
        payOutArray = [paymentReference1, paymentReference2];
        Paytr_Test.payOutERC20Invoice(payOutArray);

        uint256 interestAlice = getAlicesBaseAssetBalance() - aliceBaseAssetBalanceBeforePayOut; //not substracting amountToPay because paymentReference3 is not in the payOutArray
        uint256 interestBob = getBobsBaseAssetBalance() - bobBaseAssetBalanceBeforePayOut - amountToPay; //substracting amountToPay because bob receives 1000e6 from paymentReference1
        uint256 interestCharlie = getCharliesBaseAssetBalance() - charlieBaseAssetBalanceBeforePayOut - amountToPay; //substracting amountToPay because charlie receives 1000e6 from paymentReference2
        uint256 contractBaseAssetBalanceAfterPayOut = baseAsset.balanceOf(address(Paytr_Test));
        uint256 grossInterest = interestAlice + interestBob + (contractBaseAssetBalanceAfterPayOut - contractBaseAssetBalanceBeforePayOut);
        uint256 contractWrapperBalanceAfterPayOut = getContractCometWrapperBalance();

        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), aliceBaseAssetBalanceBeforePayment - amountToPay + interestAlice); //alice receives interest from paymentReference1 and paid 1000e6 (ref. 1)
        assertEq(getBobsBaseAssetBalance(), bobBaseAssetBalanceBeforePayment - amountToPay + amountToPay + interestBob); //bob receives interest from paymentReference2, paid 1000e6 (ref. 2) and received 1000e6 (ref. 1)
        assertEq(getCharliesBaseAssetBalance(), charlieBaseAssetBalanceBeforePayment - amountToPay + amountToPay); //charlie does not receive interest, because paymentReference3 is not in the payOut array. He paid 1000e6 (ref. 3) and receives 1000e6 (ref. 2)
        assertEq(interestCharlie, 0);
        assert(baseAsset.balanceOf(address(Paytr_Test)) > 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertApproxEqAbs(contractBaseAssetBalanceAfterPayOut, grossInterest * 1000 / 10000, 2); //value of 2 because of rounding differences from Comet and/or CometWrapper

        // //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);

        //cometWrapper (wcbaseAssetv3) balances
        assert(getContractCometWrapperBalance() > 0); //needs to be > 0 because paymentReference3 is not paid out
        assertEq(getContractCometWrapperBalance(), contractWrapperBalanceAfterPayOut);
    
    }

    function test_sendBaseAssetBalance() public {
        test_payThreePayOutTwo();
        vm.prank(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496); //0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 is the default msg.sender in Foundry (== contract owner)
        Paytr_Test.claimBaseAssetBalance();
    }

}
