// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

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

    function test_payInvoiceERC20SingleZeroFeeEscrow() public {

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > amountToPay);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, 0, 0, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20Escrow(
            bob,
            dummyFeeAddress,
            amountToPay,
            0,
            paymentReference1,
            0
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

    function test_payInvoiceERC20SingleWithFeeEscrow() public {

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > amountToPay);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, 0, 10000, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20Escrow(
            bob,
            dummyFeeAddress,
            amountToPay,
            10000,
            paymentReference1,
            0
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

    function test_payAndUpdateSingleZeroFeeEscrow() external {
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > amountToPay);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, 0, 10000, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20Escrow(
            bob,
            dummyFeeAddress,
            amountToPay,
            10000,
            paymentReference1,
            0
        );

        vm.warp(block.timestamp + 1 days);
         console2.log("Due date:",Paytr_Test.getMapping(paymentReference1).dueDate);
        console2.log("Amount:",Paytr_Test.getMapping(paymentReference1).amount);

        updateDueDate(paymentReference1);
        vm.stopPrank();

        console2.log("Due date:",Paytr_Test.getMapping(paymentReference1).dueDate);
        console2.log("Amount:",Paytr_Test.getMapping(paymentReference1).amount);

        payOutArray = [paymentReference1];

        //payout the reference that was just updated
        Paytr_Test.payOutERC20Invoice(payOutArray);

    }

    function updateDueDate(bytes storage _paymentrefence) internal {
        vm.startPrank(alice);
        Paytr_Test.releaseEscrowPayment(_paymentrefence);
        vm.stopPrank();
    }

    // function test_payInvoiceERC20DoubleEscrow() public {

    //     assertGt(baseAsset.allowance(alice, address(Paytr_Test)), amountToPay);
    //     assertGt(baseAsset.allowance(bob, address(Paytr_Test)), amountToPay);

    //     vm.expectEmit(address(Paytr_Test));        

    //     emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference1);

    //     vm.startPrank(alice);
    //     Paytr_Test.payInvoiceERC20(
    //         bob,
    //         dummyFeeAddress,
    //         uint40(block.timestamp + 10 days),
    //         amountToPay,
    //         0,
    //         paymentReference1,
    //         1
    //     );
    //     vm.stopPrank();

    //     //baseAsset balances
    //     assertEq(getAlicesBaseAssetBalance(), 10000e6 - amountToPay);
    //     assertEq(getBobsBaseAssetBalance(), 10000e6);
    //     assertEq(getCharliesBaseAssetBalance(), 10000e6);
    //     assertEq(baseAsset.balanceOf(dummyFeeAddress), 0);
    //     assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);
        
    //     //comet (cbaseAssetv3) balances
    //     assertEq(comet.balanceOf(alice), 0);
    //     assertEq(comet.balanceOf(bob), 0);
    //     assertEq(comet.balanceOf(charlie), 0);
    //     assertEq(comet.balanceOf(dummyFeeAddress), 0);
    //     assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
    //     //cometWrapper (wcbaseAssetv3) balances
    //     assertApproxEqRel(getContractCometWrapperBalance(), amountToPay, 0.1e18);

    //     uint256 contractCometWrapperBalanceBeforeSecondPayment = getContractCometWrapperBalance();

    //     vm.expectEmit(address(Paytr_Test));        

    //     emit PaymentERC20Event(baseAssetAddress, charlie, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference2);

    //     vm.startPrank(bob);
    //     Paytr_Test.payInvoiceERC20(
    //         charlie,
    //         dummyFeeAddress,
    //         uint40(block.timestamp + 10 days),
    //         amountToPay,
    //         0,
    //         paymentReference2,
    //         0       
    //     );
    //     vm.stopPrank();

    //     uint256 contractCometWrapperBalanceAfterSecondPayment = getContractCometWrapperBalance();

    //     //baseAsset balances
    //     assertEq(getBobsBaseAssetBalance(), 10000e6 - amountToPay);
    //     assertEq(getCharliesBaseAssetBalance(), 10000e6);
    //     assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

    //     //comet (cbaseAssetv3) balances
    //     assertEq(comet.balanceOf(alice), 0);
    //     assertEq(comet.balanceOf(bob), 0);
    //     assertEq(comet.balanceOf(charlie), 0);
    //     assertEq(comet.balanceOf(address(Paytr_Test)), 0);          
        
    //     //cometWrapper (wcbaseAssetv3) balances
    //     assertApproxEqRel(contractCometWrapperBalanceAfterSecondPayment, contractCometWrapperBalanceBeforeSecondPayment + amountToPay, 0.1e18);

    // }

    // function test_payAndRedeemSingleZeroFee() public {
    //     assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);
    //     vm.expectEmit(address(Paytr_Test));        

    //     emit PaymentERC20Event(baseAssetAddress, bob, dummyFeeAddress, amountToPay, uint40(block.timestamp + 10 days), 0, paymentReference1);

    //     vm.prank(alice);
    //     Paytr_Test.payInvoiceERC20(
    //         bob,
    //         dummyFeeAddress,
    //         uint40(block.timestamp + 10 days),
    //         amountToPay,
    //         0,
    //         paymentReference1,
    //         1
    //     );

    //     uint256 aliceBAseAssetBalanceBeforePayOut = getAlicesBaseAssetBalance();
    //     payOutArray = [paymentReference1];
        
    //     //increase time to gain interest
    //     vm.warp(block.timestamp + 120 days);

    //     vm.expectEmit(address(Paytr_Test));        

    //     emit PayOutERC20Event(
    //         baseAssetAddress,
    //         Paytr_Test.getMapping(paymentReference1).payee,
    //         Paytr_Test.getMapping(paymentReference1).feeAddress,
    //         Paytr_Test.getMapping(paymentReference1).amount,
    //         paymentReference1,
    //         0
    //     );
        
    //     Paytr_Test.payOutERC20Invoice(payOutArray);

    //     uint256 interestAmount = getAlicesBaseAssetBalance() - aliceBAseAssetBalanceBeforePayOut;
    //     uint256 expectedAlicesBaseAssetBalance = interestAmount + aliceBAseAssetBalanceBeforePayOut;
    //     uint256 contractBaseAssetBalance = baseAsset.balanceOf(address(Paytr_Test));

    //     emit InterestPayoutEvent(
    //         baseAssetAddress, 
    //         Paytr_Test.getMapping(paymentReference1).payee,
    //         interestAmount,
    //         paymentReference1
    //     );        
        
    //     //baseAsset balances
    //     assertEq(getAlicesBaseAssetBalance(), expectedAlicesBaseAssetBalance); //alice receives interest after the payOutERC20Invoice has been called
    //     assertEq(getBobsBaseAssetBalance(), 10000e6 + amountToPay); //Bob's starting balance is 10000e6, and he is the payee of the invoice getting paid out
    //     assertEq(getCharliesBaseAssetBalance(), 10000e6);
    //     assertGt(baseAsset.balanceOf(address(Paytr_Test)), 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
    //     assertEq(getDummyFeeBaseAssetBalance(), 0);
    //     assertApproxEqAbs(contractBaseAssetBalance, (interestAmount + contractBaseAssetBalance) * 1000 / 10000, 1); ////value of 1 because of rounding differences from Comet or CometWrapper

    //     //comet (cbaseAssetv3) balances
    //     assertEq(comet.balanceOf(alice), 0, "Alice's comet balance != 0");
    //     assertEq(comet.balanceOf(bob), 0, "Bob's comet balance != 0");
    //     assertEq(comet.balanceOf(charlie), 0, "Charlie's comet balance != 0");
    //     assertEq(comet.balanceOf(address(Paytr_Test)), 0,  "Contract comet balance != 0");

    //     //cometWrapper (wcbaseAssetv3) balances
    //     assertEq(getContractCometWrapperBalance(), 0);

    // }

    
}
