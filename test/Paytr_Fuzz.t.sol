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

    IERC20 comet = IERC20(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e);
    IERC20 baseAsset = IERC20(IComet(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e).baseToken());
    address baseAssetAddress = IComet(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e).baseToken();
    IERC20 cometWrapper = IERC20(0x99C37e76B38165389cBB163dAa74ac3f9Aa0e27F);

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    address dummyFeeAddress = address(0x4);
    address owner = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);

    bytes paymentReference1 = "0x494e56332d32343001";
    bytes paymentReference2 = "0x494e56332d32343002";
    bytes paymentReference3 = "0x494e56332d32343003";

    bytes[] public payOutArray;

    event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint40 dueDate, uint256 feeAmount, bytes paymentReference);
    event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference, uint256 feeAmount);
    event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);
    event ContractParametersUpdatedEvent(uint16 feeModifier, uint256 minDueDateParameter, uint256 maxDueDateParameter, uint256 minAmount, uint8 maxPayoutArraySize);
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
            0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e,
            0x99C37e76B38165389cBB163dAa74ac3f9Aa0e27F,
            9000,
            7 days,
            365 days,
            10e6,
            30
        );

        vm.label(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e, "Comet");
        vm.label(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, "USDC");
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(charlie, "charlie");
        vm.label(address(this), "Paytr");
        vm.label(0x399F5EE127ce7432E4921a61b8CF52b0af52cbfE, "ERC20FeeProxy contract");

        //deal baseAsset
        deal(address(baseAsset), alice, 2**256 - 1);
        uint256 balanceAlice = baseAsset.balanceOf(alice);
        assertEq(balanceAlice, 2**256 - 1);
        deal(address(baseAsset), bob, 2**256 - 1);
        uint256 balanceBob = baseAsset.balanceOf(bob);
        assertEq(balanceBob, 2**256 - 1);
        deal(address(baseAsset), charlie, 2**256 - 1);
        uint256 balanceCharlie = baseAsset.balanceOf(charlie);
        assertEq(balanceCharlie, 2**256 - 1);

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

        Paytr_Test.setERC20FeeProxy(0x399F5EE127ce7432E4921a61b8CF52b0af52cbfE);
    }

    function testFuzz_payInvoiceERC20SingleZeroFee(uint256 _amount, address _payee) public {
        vm.assume(_amount >= 10000000 && _amount <= 100000000000);
        vm.assume(_payee != address(0));

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > _amount);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, _payee, dummyFeeAddress, _amount, uint40(block.timestamp + 10 days), 0, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            0,
            paymentReference1,
            1
        );
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 2**256 - 1 - _amount);
        assertEq(getBobsBaseAssetBalance(), 2**256 - 1);
        assertEq(getCharliesBaseAssetBalance(), 2**256 - 1);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(_payee), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(getContractCometWrapperBalance(), _amount, 0.1e18);

    }

    function testFuzz_payInvoiceERC20SingleWithFee(uint256 _amount, uint256 _feeAmount, address _payee, address _feeAddress) public {
        vm.assume(_amount >= 10000000 && _amount <= 100000000000);
        vm.assume(_feeAmount <= 100000000000);
        vm.assume(_payee != address(0));
        vm.assume(_feeAmount > 0);
        vm.assume(_feeAddress != address(0));

        assertGe(baseAsset.allowance(alice, address(Paytr_Test)), _amount + _feeAmount);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, _payee, _feeAddress, _amount, uint40(block.timestamp + 10 days), _feeAmount, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            _feeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            _feeAmount,
            paymentReference1,
            1
        );
        
        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 2**256 - 1 - _amount - _feeAmount);
        assertEq(getBobsBaseAssetBalance(), 2**256 - 1);
        assertEq(getCharliesBaseAssetBalance(), 2**256 - 1);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(_payee), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(getContractCometWrapperBalance(), _amount + _feeAmount, 0.1e18);

    }

    function testFuzz_payInvoiceERC20Double(uint256 _amount, uint256 _feeAmount, address _payee, address _feeAddress) public {
        vm.assume(_amount >= 10000000 && _amount <= 100000000000);
        vm.assume(_feeAmount <= 100000000000);
        vm.assume(_payee != address(0));
        vm.assume(_feeAmount > 0);
        vm.assume(_feeAddress != address(0));

        assertGe(baseAsset.allowance(alice, address(Paytr_Test)), _amount + _feeAmount);
        assertGe(baseAsset.allowance(bob, address(Paytr_Test)), _amount + _feeAmount);

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, _payee, _feeAddress, _amount, uint40(block.timestamp + 10 days), _feeAmount, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            _feeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            _feeAmount,
            paymentReference1,
            1
        );
        vm.stopPrank();

        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), 2**256 - 1 - _amount - _feeAmount);
        assertEq(getBobsBaseAssetBalance(), 2**256 - 1);
        assertEq(getCharliesBaseAssetBalance(), 2**256 - 1);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);
        
        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(_payee), 0);
        assertEq(comet.balanceOf(charlie), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);       
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(getContractCometWrapperBalance(), _amount + _feeAmount, 0.1e18);

        uint256 contractCometWrapperBalanceBeforeSecondPayment = getContractCometWrapperBalance();

        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, _payee, _feeAddress, _amount, uint40(block.timestamp + 10 days), _feeAmount, paymentReference2);

        vm.startPrank(bob);
        Paytr_Test.payInvoiceERC20(
            _payee,
            _feeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            _feeAmount,
            paymentReference2,
            0       
        );
        vm.stopPrank();

        uint256 contractCometWrapperBalanceAfterSecondPayment = getContractCometWrapperBalance();

        //baseAsset balances
        assertEq(getBobsBaseAssetBalance(), 2**256 - 1 - _amount - _feeAmount);
        assertEq(getCharliesBaseAssetBalance(), 2**256 - 1);
        assertEq(baseAsset.balanceOf(address(Paytr_Test)), 0);

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0);
        assertEq(comet.balanceOf(bob), 0);
        assertEq(comet.balanceOf(_feeAddress), 0);
        assertEq(comet.balanceOf(address(Paytr_Test)), 0);          
        
        //cometWrapper (wcbaseAssetv3) balances
        assertApproxEqRel(contractCometWrapperBalanceAfterSecondPayment, contractCometWrapperBalanceBeforeSecondPayment + _amount + _feeAmount, 0.1e18);

    }

    function testFuzz_payAndRedeemSingleZeroFee(uint256 _amount, address _payee) public {
        vm.assume(_amount >= 10000000 && _amount <= 100000000000);
        vm.assume(_payee != address(0) && _payee != alice && _payee != bob && _payee != charlie); //_payee cannot be alice, bob or charlie because they are dealt the max. amount of USDC. This can cause addition overflow in the payout
        assert(baseAsset.allowance(alice, address(Paytr_Test)) >= _amount);
        
        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, _payee, dummyFeeAddress, _amount, uint40(block.timestamp + 10 days), 0, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            0,
            paymentReference1,
            1
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
        uint256 contractBaseAssetBalance = baseAsset.balanceOf(address(Paytr_Test));

        emit InterestPayoutEvent(
            baseAssetAddress, 
            Paytr_Test.getMapping(paymentReference1).payee,
            interestAmount,
            paymentReference1
        );   
        
        //baseAsset balances
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

    function testFuzz_payAndRedeemSingleWithFee(uint256 _amount, uint256 _feeAmount, address _payee, address _feeAddress) public {
        vm.assume(_amount >= 10000000 && _amount <= 100000000000);
        vm.assume(_feeAmount > 0 && _feeAmount <= 100000000000);
        vm.assume(_payee != address(0) && _payee != alice && _payee != bob && _payee != charlie); //_payee cannot be alice, bob or charlie because they are dealt the max. amount of USDC. This can cause addition overflow in the payout
        vm.assume(_feeAddress != address(0) && _feeAddress != alice && _feeAddress != bob && _feeAddress != charlie);
        
        assert(baseAsset.allowance(alice, address(Paytr_Test)) >= _amount + _feeAmount);
        
        vm.expectEmit(address(Paytr_Test));        

        emit PaymentERC20Event(baseAssetAddress, _payee, _feeAddress, _amount, uint40(block.timestamp + 10 days), _feeAmount, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            _feeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            _feeAmount,
            paymentReference1,
            1
        );

        uint256 aliceBaseAssetBalanceBeforePayOut = getAlicesBaseAssetBalance();
        uint256 contractBaseAssetBalanceBeforePayOut = baseAsset.balanceOf(address(Paytr_Test));

        payOutArray = [paymentReference1];
        
        //increase time to gain interest
        vm.warp(block.timestamp + 120 days);

        vm.expectEmit(address(0x131eb294E3803F23dc2882AB795631A12D1d8929));

        emit TransferWithReferenceAndFee(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            Paytr_Test.getMapping(paymentReference1).feeAmount,
            Paytr_Test.getMapping(paymentReference1).feeAddress
        );

        vm.expectEmit(address(Paytr_Test));        

        emit PayOutERC20Event(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference1).payee,
            Paytr_Test.getMapping(paymentReference1).feeAddress,
            Paytr_Test.getMapping(paymentReference1).amount,
            paymentReference1,
            Paytr_Test.getMapping(paymentReference1).feeAmount
        );
        
        Paytr_Test.payOutERC20Invoice(payOutArray);

        uint256 interestAmount = getAlicesBaseAssetBalance() - aliceBaseAssetBalanceBeforePayOut;

        uint256 interestAlice = getAlicesBaseAssetBalance() - aliceBaseAssetBalanceBeforePayOut; //not substracting amountToPay because paymentReference3 is not in the payOutArray
        uint256 contractBaseAssetBalanceAfterPayOut = baseAsset.balanceOf(address(Paytr_Test));
        uint256 grossInterest = interestAlice + (contractBaseAssetBalanceAfterPayOut - contractBaseAssetBalanceBeforePayOut);

        emit InterestPayoutEvent(
            baseAssetAddress, 
            Paytr_Test.getMapping(paymentReference1).payee,
            interestAmount,
            paymentReference1
        );   
        
        //baseAsset balances
        assertGt(baseAsset.balanceOf(address(Paytr_Test)), contractBaseAssetBalanceBeforePayOut); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertApproxEqAbs(contractBaseAssetBalanceAfterPayOut, grossInterest * 1000 / 10000, 2); //value of 2 because of rounding differences from Comet and/or CometWrapper


        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0, "Alice's comet balance != 0");
        assertEq(comet.balanceOf(bob), 0, "Bob's comet balance != 0");
        assertEq(comet.balanceOf(charlie), 0, "Charlie's comet balance != 0");
        assertEq(comet.balanceOf(address(Paytr_Test)), 0,  "Contract comet balance != 0");

        //cometWrapper (wcbaseAssetv3) balances
        assertEq(getContractCometWrapperBalance(), 0);

    }

    function testFuzz_payThreePayOutTwoZeroFee(uint256 _amount, address _payee) public {
        vm.assume(_amount >= 10000000 && _amount <= 100000000000);
        vm.assume(_payee != address(0) && _payee != alice && _payee != bob && _payee != charlie); //_payee cannot be alice, bob or charlie because they are dealt the max. amount of USDC. This can cause addition overflow in the payout
        assert(baseAsset.allowance(alice, address(Paytr_Test)) >= _amount);
        assert(baseAsset.allowance(bob, address(Paytr_Test)) >= _amount);

        uint256 aliceBaseAssetBalanceBeforePayment = getAlicesBaseAssetBalance();
        uint256 bobBaseAssetBalanceBeforePayment = getBobsBaseAssetBalance();
        uint256 charlieBaseAssetBalanceBeforePayment = getCharliesBaseAssetBalance();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, _payee, dummyFeeAddress, _amount, uint40(block.timestamp + 10 days), 0, paymentReference1);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            _amount,
            0,
            paymentReference1,
            0
        );
        vm.stopPrank();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, _payee, dummyFeeAddress, _amount, uint40(block.timestamp + 12 days), 0, paymentReference2);

        vm.startPrank(bob);
        Paytr_Test.payInvoiceERC20(
            _payee,
            dummyFeeAddress,
            uint40(block.timestamp + 12 days),
            _amount,
            0,
            paymentReference2,
            1
        );
        vm.stopPrank();

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, _payee, dummyFeeAddress, _amount, uint40(block.timestamp + 40 days), 0, paymentReference3);

        vm.startPrank(charlie);
        Paytr_Test.payInvoiceERC20(
            _payee,
            dummyFeeAddress,
            uint40(block.timestamp +40 days),
            _amount,
            0,
            paymentReference3,
            0
        );
        vm.stopPrank();

        assertEq(getAlicesBaseAssetBalance(), aliceBaseAssetBalanceBeforePayment - _amount, "Alice's base balance mismatch");
        assertEq(getBobsBaseAssetBalance(), bobBaseAssetBalanceBeforePayment - _amount, "Bobs's base balance mismatch");
        assertEq(getCharliesBaseAssetBalance(), charlieBaseAssetBalanceBeforePayment - _amount, "Charlie's base balance mismatch");

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

        vm.expectEmit(address(0x131eb294E3803F23dc2882AB795631A12D1d8929));

        emit TransferWithReferenceAndFee(
            baseAssetAddress,
            Paytr_Test.getMapping(paymentReference2).payee,
            Paytr_Test.getMapping(paymentReference2).amount,
            paymentReference2,
            Paytr_Test.getMapping(paymentReference2).feeAmount,
            Paytr_Test.getMapping(paymentReference2).feeAddress
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
        uint256 interestBob = getBobsBaseAssetBalance() - bobBaseAssetBalanceBeforePayOut;
        uint256 interestCharlie = getCharliesBaseAssetBalance() - charlieBaseAssetBalanceBeforePayOut;
        uint256 contractBaseAssetBalanceAfterPayOut = baseAsset.balanceOf(address(Paytr_Test));
        uint256 grossInterest = interestAlice + interestBob + (contractBaseAssetBalanceAfterPayOut - contractBaseAssetBalanceBeforePayOut);
        uint256 contractWrapperBalanceAfterPayOut = getContractCometWrapperBalance();

        //baseAsset balances
        assertEq(getAlicesBaseAssetBalance(), aliceBaseAssetBalanceBeforePayment - _amount + interestAlice, "Alice's baseAsset balance mismatch"); //alice receives interest from paymentReference1 and paid ref. 1
        assertEq(getBobsBaseAssetBalance(), bobBaseAssetBalanceBeforePayment - _amount + interestBob, "Bob's base balance mismatch"); //bob receives interest from paymentReference2 and paid ref. 2
        assertEq(getCharliesBaseAssetBalance(), charlieBaseAssetBalanceBeforePayment - _amount, "Charlie's base balance mismatch"); //charlie does not receive interest, because paymentReference3 is not in the payOut array. He paid ref. 3
        assertEq(interestCharlie, 0, "Charlie's interest != 0");
        assertGt(baseAsset.balanceOf(address(Paytr_Test)), 0); //the contract receives 10% of the interest amount as fee (param 9000 in setUp)
        assertApproxEqAbs(contractBaseAssetBalanceAfterPayOut, grossInterest * 1000 / 10000, 2); //value of 2 because of rounding differences from Comet and/or CometWrapper

        //comet (cbaseAssetv3) balances
        assertEq(comet.balanceOf(alice), 0, "Alice's comet balance != 0");
        assertEq(comet.balanceOf(bob), 0, "Bob's comet balance != 0");
        assertEq(comet.balanceOf(charlie), 0, "Charlie's comet balance != 0");
        assertEq(comet.balanceOf(address(Paytr_Test)), 0, "Contract comet balance != 0");

        //cometWrapper (wcbaseAssetv3) balances
        assertGt(getContractCometWrapperBalance(), 0); //needs to be > 0 because paymentReference3 is not paid out
        assertEq(getContractCometWrapperBalance(), contractWrapperBalanceAfterPayOut, "Contract wrapper balance != wrapper balance after payout");
    
    }

    function testFuzz_usePaymentReferenceTwiceAfterPayout(uint256 _amount, address _payee, address _payee2) public {
        //this test checks whether it's possible to pay a certain reference, have it paid out and use the same reference again
        vm.assume(_amount >= 10000000 && _amount < 1_000_000_000_000_000); //prevent overflow if one of the payees has a high amount of baseAsset
        vm.assume(_payee != address(0) && _payee != alice && _payee != bob && _payee != charlie); //_payee cannot be alice, bob or charlie because they are dealt the max. amount of USDC. This can cause addition overflow in the payout
        vm.assume(_payee2 != address(0) && _payee2 != alice && _payee2 != bob && _payee2 != charlie);
        vm.assume(_payee != _payee2);
        assert(baseAsset.allowance(alice, address(Paytr_Test)) > _amount);

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, _payee, dummyFeeAddress, _amount, uint40(block.timestamp + 25 days), 0, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            dummyFeeAddress,
            uint40(block.timestamp + 25 days),
            _amount,
            0,
            paymentReference1,
            0
        );

        vm.warp(block.timestamp + 25 days);

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

        vm.warp(block.timestamp + 5 days);

        vm.expectEmit(address(Paytr_Test));
        emit PaymentERC20Event(baseAssetAddress, _payee2, dummyFeeAddress, 10e6, uint40(block.timestamp + 10 days), 0, paymentReference1);

        vm.prank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee2,
            dummyFeeAddress,
            uint40(block.timestamp + 10 days),
            10e6,
            0,
            paymentReference1,
            0
        );

    }

    function testFuzz_paymentThroughRequestNetwork(uint256 _amount, uint256 _feeAmount, address _payee, address _feeAddress) public {
        vm.assume(_amount < 100e12 && _amount > 0 && _feeAmount < 100e12);
        console2.log(Paytr_Test.minTotalAmountParameter());
        vm.assume((_amount + _feeAmount) >= Paytr_Test.minTotalAmountParameter());
        vm.assume(_payee != address(0) && _payee != alice && _payee != bob && _payee != charlie); //_payee cannot be alice, bob or charlie because they are dealt the max. amount of USDC. This can cause addition overflow in the payout
        vm.assume(_feeAddress != address(0) && _feeAddress != alice && _feeAddress != bob && _feeAddress != charlie);

        assert(baseAsset.allowance(alice, address(Paytr_Test)) > 1000e6);

        vm.expectEmit();
        emit PaymentERC20Event(baseAssetAddress, _payee, _feeAddress, _amount, uint40(block.timestamp + 28 days), _feeAmount, paymentReference3);

        vm.startPrank(alice);
        Paytr_Test.payInvoiceERC20(
            _payee,
            _feeAddress,
            uint40(block.timestamp + 28 days),
            _amount,
            _feeAmount,
            paymentReference3,
            1
        );

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

    function testFuzz_sendBaseAssetBalance(uint256 _amount, address _payee) public {
        vm.assume(_amount > 0 && _amount < 100e12);
        vm.assume(_payee != alice && _payee != bob && _payee != charlie);
        uint256 contractBaseAssetBalanceBeforePayOut = getContractBaseAssetBalance();

        testFuzz_payThreePayOutTwoZeroFee(_amount, _payee);

        vm.prank(owner);
        Paytr_Test.claimBaseAssetBalance();

        assertGe(baseAsset.balanceOf(owner), 0);
        assertLe(getContractBaseAssetBalance(), contractBaseAssetBalanceBeforePayOut); //feeModifier can be 10000 (no fee applied), so contract base asset balance won't change
    }

}