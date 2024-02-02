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

    uint256 amountToPay = 1000e6;

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

    bytes[] payOutArray;

    event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint40 dueDate, uint256 feeAmount, bytes paymentReference);
    event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference, uint256 feeAmount);
    event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);
    event ContractParametersUpdatedEvent(uint16 contractFeeModifier, uint256 minDueDateParameter, uint256 maxDueDateParameter, uint256 minAmount, uint8 maxPayoutArraySize);
    event setERC20FeeProxyEvent(address ERC20FeeProxyAddress);
    
    //external contracts events:
    event TransferWithReferenceAndFee(address tokenAddress, address to, uint256 amount, bytes indexed paymentReference, uint256 feeAmount, address feeAddress);

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

    function getDummyFeeBaseAssetBalance() public view returns(uint256) {
        uint256 dummyFeesBaseAssetBalance = baseAsset.balanceOf(dummyFeeAddress);
        return dummyFeesBaseAssetBalance;
    }

    function setUp() public {
        Paytr_Test = new Paytr(
            0xF09F0369aB0a875254fB565E52226c88f10Bc839,
            0x797D7126C35E0894Ba76043dA874095db4776035,
            9000,
            7 days,
            365 days,
            10e6,
            30
        );

        vm.label(0xF09F0369aB0a875254fB565E52226c88f10Bc839, "Comet");
        vm.label(0xDB3cB4f2688daAB3BFf59C24cC42D4B6285828e9, "USDC");
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(charlie, "charlie");
        vm.label(address(this), "Paytr");
        vm.label(0x131eb294E3803F23dc2882AB795631A12D1d8929, "ERC20FeeProxy contract");


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

        Paytr_Test.setERC20FeeProxy(0x131eb294E3803F23dc2882AB795631A12D1d8929);
    }

    function test_payInvoiceERC20SingleZeroFee() public {

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > amountToPay);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference1);

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
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 10000e6 - amountToPay);
        assertEq(getBobsBaseAssetBalance(), 10000e6);
        assertEq(getCharliesBaseAssetBalance(), 10000e6);
        assertEq(getDummyFeeBaseAssetBalance(), 0);
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

    function test_payInvoiceERC20SingleWithFee() public {

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > amountToPay);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 10000, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            10000,
            paymentReference1,
            false
        );
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 10000e6 - amountToPay - 10000);
        assertEq(getBobsBaseAssetBalance(), 10000e6);
        assertEq(getCharliesBaseAssetBalance(), 10000e6);
        assertEq(getDummyFeeBaseAssetBalance(), 0);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(dummyFeeAddress), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(getContractCometWrapperBalance(), amountToPay + 10000, 0.1e18);

    }

    function test_payInvoiceERC20Double() public {

        assertGt(baseAsset.allowance(alice, address(Paytr_Test)), amountToPay);
        assertGt(baseAsset.allowance(bob, address(Paytr_Test)), amountToPay);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            true
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

        emit PaymentERC20Event(baseAssetAddress, charlie, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference2);

        vm.startPrank(bob);
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
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

    function test_payAndRedeemSingleZeroFee() public {
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            true
        );

        uint256 aliceBAseAssetBalanceBeforePayOut = getAlicesBaseAssetBalance();
        payOutArray = [paymentReference1];
        
        //increase time to gain interest
        vm.warp(block.timestamp + 120 days);

        vm.expectEmit(address(Paytr_Test));        

        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).feeAddress,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            0
        );
        
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
        assertGt(baseAsset.balanceOf(address(Paytr_Test)), 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertEq(getDummyFeeBaseAssetBalance(), 0);
        assertApproxEqAbs(contractBaseAssetBalance, (interestAmount + contractBaseAssetBalance) * 1000 / 10000, 1); ////value of 1 because of rounding differences from Comet or CometWrapper

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0, "Alice's comet balance != 0");
        assertEq(comet.balanceOf(bob), 0, "Bob's comet balance != 0");
        assertEq(comet.balanceOf(charlie), 0, "Charlie's comet balance != 0");
        assertEq(comet.balanceOf(address(Paytr_Test)), 0,  "Contract comet balance != 0");

        //cometWrapper (wcbaseAssetv3) balances
        assertEq(getContractCometWrapperBalance(), 0);

    }

    function test_payFiveReferencesAndPayOutNoFee() public {
        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference2,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference3,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference4,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference5,
            false
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 30 days);

        payOutArray = [paymentReference1, paymentReference2, paymentReference3, paymentReference4, paymentReference5];
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function test_payTenReferencesAndPayOutNoFee() public {
        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference2,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference3,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference4,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference5,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference6,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference7,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference8,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference9,
            false
        );

        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference10,
            false
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 30 days);

        payOutArray = [paymentReference1, paymentReference2, paymentReference3, paymentReference4, paymentReference5, paymentReference6, paymentReference7, paymentReference8, paymentReference9, paymentReference10];
        Paytr_Test.payOutERC20Invoice(payOutArray);
    }

    function test_payAndRedeemSingleWithFee() public {
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        test_payInvoiceERC20SingleWithFee();

        uint256 aliceBAseAssetBalanceBeforePayOut = getAlicesBaseAssetBalance();
        payOutArray = [paymentReference1];
        
        //increase time to gain interest
        vm.warp(block.timestamp + 120 days);

        vm.expectEmit(address(Paytr_Test));        

        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).feeAddress,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            10000
        );
        
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
        assertEq(getDummyFeeBaseAssetBalance(), 10000);
        assertGt(baseAsset.balanceOf(address(Paytr_Test)), 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertApproxEqAbs(contractBaseAssetBalance, (interestAmount + contractBaseAssetBalance) * 1000 / 10000, 1); ////value of 1 because of rounding differences from Comet or CometWrapper

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0, "Alice's comet balance != 0");
        assertEq(comet.balanceOf(bob), 0, "Bob's comet balance != 0");
        assertEq(comet.balanceOf(charlie), 0, "Charlie's comet balance != 0");
        assertEq(comet.balanceOf(address(Paytr_Test)), 0,  "Contract comet balance != 0");

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
        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference1); //payer alice, payee bob

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        vm.stopPrank();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, charlie, dummyFeeAddress, amountToPay, uint40(block.timestamp + 12 days), 0, paymentReference2); //payer bob, payee charlie

        vm.startPrank(bob);
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            uint40(block.timestamp + 12 days),
            amountToPay,
            0,
            paymentReference2,
            false
        );
        vm.stopPrank();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, alice, dummyFeeAddress, amountToPay, uint40(block.timestamp + 40 days), 0, paymentReference3); //payer charlie, payee alice

        vm.startPrank(charlie);
        Paytr_Test.payInvoiceERC20(
            alice,
            dummyFeeAddress,
            uint40(block.timestamp + 40 days),
            amountToPay,
            0,
            paymentReference3,
            false
        );
        vm.stopPrank();

        assertEq(getAlicesBaseAssetBalance(), aliceBaseAssetBalanceBeforePayment - amountToPay, "Alice's base balance mismatch");
        assertEq(getBobsBaseAssetBalance(), bobBaseAssetBalanceBeforePayment - amountToPay, "Bobs's base balance mismatch");
        assertEq(getCharliesBaseAssetBalance(), charlieBaseAssetBalanceBeforePayment - amountToPay, "Charlie's base balance mismatch");

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
        assertEq(getAlicesBaseAssetBalance(), aliceBaseAssetBalanceBeforePayment - amountToPay + interestAlice, "Alice's base balance mismatch"); //alice receives interest from paymentReference1 and paid 1000e6 (ref. 1)
        assertEq(getBobsBaseAssetBalance(), bobBaseAssetBalanceBeforePayment - amountToPay + amountToPay + interestBob, "Bob's base balance mismatch"); //bob receives interest from paymentReference2, paid 1000e6 (ref. 2) and received 1000e6 (ref. 1)
        assertEq(getCharliesBaseAssetBalance(), charlieBaseAssetBalanceBeforePayment - amountToPay + amountToPay, "Charlie's base balance mismatch"); //charlie does not receive interest, because paymentReference3 is not in the payOut array. He paid 1000e6 (ref. 3) and receives 1000e6 (ref. 2)
        assertEq(interestCharlie, 0, "Charlie's interest != 0");
        assertGt(baseAsset.balanceOf(address(Paytr_Test)), 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertApproxEqAbs(contractBaseAssetBalanceAfterPayOut, grossInterest * 1000 / 10000, 2); //value of 2 because of rounding differences from Comet and/or CometWrapper

        // //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0, "Alice's comet balance != 0");
        assertEq(comet.balanceOf(bob), 0, "Bob's comet balance != 0");
        assertEq(comet.balanceOf(charlie), 0, "Charlie's comet balance != 0");
        assertEq(comet.balanceOf(address(Paytr_Test)), 0, "Contract comet balance != 0");

        //cometWrapper (wcbaseAssetv3) balances
        assertGt(getContractCometWrapperBalance(), 0); //needs to be > 0 because paymentReference3 is not paid out
        assertEq(getContractCometWrapperBalance(), contractWrapperBalanceAfterPayOut, "Contract wrapper balance != balance affter payout");
    
    }

    function test_usePaymentReferenceTwiceAfterPayout() public {
        //this test checks whether it's possible to pay a certain reference, have it paid out and use the same reference again
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        assert(baseAsset.allowance(bob, address(Paytr_Test)) > 1000e6);
        assert(baseAsset.allowance(charlie, address(Paytr_Test)) > 1000e6);

        uint256 aliceBaseAssetBalanceBeforeFirstPayment = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceBeforeFirstPayment = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceBeforeFirstPayment = getCharliesBaseAssetBalance();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 20 days), 0, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            dummyFeeAddress,
            uint40(block.timestamp + 20 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        vm.stopPrank();

        uint256 aliceBaseAssetBalanceAfterFirstPayment = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceAfterFirstPayment = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceAfterFirstPayment = getCharliesBaseAssetBalance();

        assertEq(aliceBaseAssetBalanceAfterFirstPayment, aliceBaseAssetBalanceBeforeFirstPayment - amountToPay);
        assertEq(bobBaseAssetBalanceAfterFirstPayment, bobBaseAssetBalanceBeforeFirstPayment);
        assertEq(charlieBaseAssetBalanceAfterFirstPayment,charlieBaseAssetBalanceBeforeFirstPayment);

        vm.warp(block.timestamp + 20 days);

        vm.expectEmit(address(Paytr_Test));
        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).feeAddress,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            0
        );

        payOutArray = [paymentReference1];
        Paytr_Test.payOutERC20Invoice(payOutArray);

        uint256 aliceBaseAssetBalanceAfterPayOut = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceAfterPayOut = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceAfterPayOut = getCharliesBaseAssetBalance();

        assertGt(aliceBaseAssetBalanceAfterPayOut, aliceBaseAssetBalanceAfterFirstPayment);
        assertGt(bobBaseAssetBalanceAfterPayOut, bobBaseAssetBalanceAfterFirstPayment);
        assertEq(bobBaseAssetBalanceAfterPayOut, bobBaseAssetBalanceBeforeFirstPayment + amountToPay);
        assertEq(charlieBaseAssetBalanceAfterPayOut, charlieBaseAssetBalanceBeforeFirstPayment);

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, charlie, dummyFeeAddress, amountToPay, uint40(block.timestamp + 12 days), 0, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            charlie,
            dummyFeeAddress,
            uint40(block.timestamp + 12 days),
            amountToPay,
            0,
            paymentReference1,
            false
        );
        vm.stopPrank();

        uint256 aliceBaseAssetBalanceAfterSecondPayment = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceAfterSecondPayment = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceAfterSecondPayment = getCharliesBaseAssetBalance();

        assertLt(aliceBaseAssetBalanceAfterSecondPayment, aliceBaseAssetBalanceAfterPayOut);
        assertEq(aliceBaseAssetBalanceAfterSecondPayment, aliceBaseAssetBalanceAfterPayOut - amountToPay);
        assertEq(bobBaseAssetBalanceAfterSecondPayment, bobBaseAssetBalanceAfterPayOut);
        assertEq(charlieBaseAssetBalanceAfterSecondPayment, charlieBaseAssetBalanceAfterPayOut);

    }

    function test_paymentThroughRequestNetwork() public {
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
        uint256 feeAmount = 1e6;
        address feeAddress = address(0x9);

        vm.expectEmit();
        emit PaymentERC20Event(baseAssetAddress, bob, feeAddress, amountToPay, uint40(block.timestamp + 28 days), feeAmount, paymentReference3);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            bob,
            feeAddress,
            uint40(block.timestamp + 28 days),
            amountToPay,
            feeAmount,
            paymentReference3,
            true
        );
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 10000e6 - amountToPay - feeAmount);
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
        assertApproxEqRel(getContractCometWrapperBalance(), amountToPay + feeAmount, 0.1e18);

        vm.warp(block.timestamp + 29 days);

        vm.expectEmit(address(0x131eb294E3803F23dc2882AB795631A12D1d8929));

        emit TransferWithReferenceAndFee(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference3).payee,
            Paytr_Test.getMapping(paymentReference3).amount,
            paymentReference3,
            Paytr_Test.getMapping(paymentReference3).feeAmount,
            Paytr_Test.getMapping(paymentReference3).feeAddress
        );
        
        vm.expectEmit();

        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference3).payee,
            Paytr_Test.getMapping(paymentReference3).feeAddress,
            Paytr_Test.getMapping(paymentReference3).amount,
            paymentReference3,
            Paytr_Test.getMapping(paymentReference3).feeAmount
        );

        payOutArray = [paymentReference3];
        Paytr_Test.payOutERC20Invoice(payOutArray);
        vm.stopPrank();
    }

    function test_sendBaseAssetBalance() public {
        uint256 contractBaseAssetBalanceBeforePayOut = getContractBaseAssetBalance();

        test_payThreePayOutTwo();

        vm.prank(owner);
        Paytr_Test.claimBaseAssetBalance();

        assertGe(baseAsset.balanceOf(owner), 0);
        assertLe(getContractBaseAssetBalance(), contractBaseAssetBalanceBeforePayOut); //feeModifier can be 10000 (no fee applied), so contract base asset balance won't change
    }

    function test_setContractParameters() public {
        vm.expectEmit(address(Paytr_Test));
        emit ContractParametersUpdatedEvent(6000, 18 days, 365 days, 100e6, 25);

        vm.prank(owner);
        Paytr_Test.setContractParameters(6000, 18 days, 365 days, 100e6, 25);

    }

    function test_setERC20FeeProxy() public {
        vm.expectEmit(address(Paytr_Test));
        emit setERC20FeeProxyEvent(address(0x131eb294E3803F23dc2882AB795631A12D1d8929));
        Paytr_Test.setERC20FeeProxy(address(0x131eb294E3803F23dc2882AB795631A12D1d8929));

    }

    function test_pauseAndUnpause() public {
        vm.startPrank(owner);
        Paytr_Test.pause();
        Paytr_Test.unpause();
    }

}
