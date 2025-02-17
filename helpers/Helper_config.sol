// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Paytr} from "../src/Paytr.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}
interface IComet {
    function supply(address asset, uint amount) external;
    function withdraw(address asset, uint amount) external;
    function baseToken() external view returns (address);
    function allow(address manager, bool isAllowed) external;
    function decimals() external view returns (uint8);
}

contract Paytr_Helpers is Test {
    using SafeERC20 for IERC20;
    
    Paytr Paytr_Test;

    //SEPOLIA USDC
    // IERC20 comet = IERC20(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e);
    // address cometAddress = address(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e);
    // IERC20 baseAsset = IERC20(IComet(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e).baseToken());
    // address baseAssetAddress = IComet(0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e).baseToken();
    // IERC20 cometWrapper = IERC20(0xC3836072018B4D590488b851d574556f2EeB895a);
    // address cometWrapperAddress = address(0xC3836072018B4D590488b851d574556f2EeB895a);
    // IERC20 compToken = IERC20(0xA6c8D1c55951e8AC44a0EaA959Be5Fd21cc07531);

    // address alice = address(0x9);
    // address bob = address(0x2);
    // address charlie = address(0x3);
    // address dummyFeeAddress = address(0x4);
    // address owner = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
    // address whale = address(0x75C0c372da875a4Fc78E8A37f58618a6D18904e8);

    //POLYGON USDC
    IERC20 comet = IERC20(0xF25212E676D1F7F89Cd72fFEe66158f541246445);
    address cometAddress = address(0xF25212E676D1F7F89Cd72fFEe66158f541246445);
    IERC20 baseAsset = IERC20(IComet(0xF25212E676D1F7F89Cd72fFEe66158f541246445).baseToken());
    address baseAssetAddress = IComet(0xF25212E676D1F7F89Cd72fFEe66158f541246445).baseToken();
    IERC20 cometWrapper = IERC20(0x0cd478875450BcdC75E16FF6084aF3a4782610b9);
    address cometWrapperAddress = address(0x0cd478875450BcdC75E16FF6084aF3a4782610b9);
    IERC20 compToken = IERC20(0x8505b9d2254A7Ae468c0E9dd10Ccea3A837aef5c);
    address ERC20FeeProxy = address(0x0DfbEe143b42B41eFC5A6F87bFD1fFC78c2f0aC9);

    // address alice = address(0x9999);
    // address bob = address(0x2222);
    // address charlie = address(0x3333);
    // address dummyFeeAddress = address(0x4444);
    // address owner = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
    address whale = address(0x9c2bd617b77961ee2c5e3038dFb0c822cb75d82a);

    //POLYGON USDT
    // IERC20 comet = IERC20(0xaeB318360f27748Acb200CE616E389A6C9409a07);
    // address cometAddress = address(0xaeB318360f27748Acb200CE616E389A6C9409a07);
    // IERC20 baseAsset = IERC20(IComet(0xaeB318360f27748Acb200CE616E389A6C9409a07).baseToken());
    // address baseAssetAddress = IComet(0xaeB318360f27748Acb200CE616E389A6C9409a07).baseToken();
    // IERC20 cometWrapper = IERC20(0xc999F1577D684081588a483b5D3C470F319fd6BF);
    // address cometWrapperAddress = address(0xc999F1577D684081588a483b5D3C470F319fd6BF);
    // IERC20 compToken = IERC20(0x8505b9d2254A7Ae468c0E9dd10Ccea3A837aef5c);
    // address ERC20FeeProxy = address(0x0DfbEe143b42B41eFC5A6F87bFD1fFC78c2f0aC9);    
    // address whale = address(0x5a52E96BAcdaBb82fd05763E25335261B270Efcb);
    
    uint8 decimals = IERC20Extended(address(baseAsset)).decimals();

    address alice = address(0x9999);
    address bob = address(0x2222);
    address charlie = address(0x3333);
    address dummyFeeAddress = address(0x4444);
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

    event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint40 dueDate, uint256 feeAmount, bytes paymentReference);
    event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference, uint256 feeAmount);
    event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);
    event ContractParametersUpdatedEvent(uint16 feeModifier, uint256 minDueDateParameter, uint256 maxDueDateParameter, uint256 minAmount, uint8 maxPayoutArraySize);
    event SetERC20FeeProxyEvent(address ERC20FeeProxyAddress);
    
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

    function transferBaseAsset() internal {
        vm.startPrank(whale);
        baseAsset.transfer(alice, 5_000_000 * (10 ** decimals));
        uint256 balanceAlice = baseAsset.balanceOf(alice);
        assertEq(balanceAlice, 5_000_000 * (10 ** decimals));

        baseAsset.transfer(bob, 5_000_000 * (10 ** decimals));
        uint256 balanceBob = baseAsset.balanceOf(bob);
        assertEq(balanceBob, 5_000_000 * (10 ** decimals));

        baseAsset.transfer(charlie, 5_000_000 * (10 ** decimals));
        uint256 balanceCharlie = baseAsset.balanceOf(charlie);
        assertEq(balanceCharlie, 5_000_000 * (10 ** decimals));

        vm.stopPrank();
    }

    function approveBaseAsset() public {
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

}