// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/Utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


interface IComet {
   function supply(address asset, uint amount) external;
   function withdraw(address asset, uint amount) external;
   function baseToken() external view returns (address);
   function allow(address manager, bool isAllowed) external; }

interface IERC20FeeProxy {
   function transferFromWithReferenceAndFee(
       address _tokenAddress,
       address _to,
       uint256 _amount,
       bytes calldata _paymentReference,
       uint256 _feeAmount,
       address _feeAddress
    ) external;
}

interface IWrapper {
   function deposit(uint256 assets, address receiver) external returns (uint256 shares);
   function redeem(uint256 assets, address receiver, address owner) external returns (uint256 shares);
   function claimTo(address to) external; }

/**
* @title   Paytr
* @notice  Paytr allows you to earn by paying early.
*/

contract Paytr is Ownable, Pausable, ReentrancyGuard {
   using SafeERC20 for IERC20;

   error InvalidAmount();
   error PaymentReferenceInUse();
   error NotAuthorized();
   error ZeroAddressPayee();
   error ZeroFeeAddress();
   error DueDateNotAllowed();
   error NoPrePayment();
   error DueDateNotZero();
   error InvalidNewDueDate();
   error InvalidArrayLength();
   error ReferenceNotDue();
   error InvalidFeeModifier();
   error InvalidMinDueDate();
   error InvalidMaxDueDate();
   error InvalidMinAmount();
   error InvalidMaxArraySize();

   address immutable baseAsset;
   address ERC20FeeProxyAddress;
   address immutable  wrapperAddress;
   address immutable  cometAddress;
   uint8 maxPayoutArraySize;
   uint16 feeModifier;
   uint256 minDueDateParameter;
   uint256 maxDueDateParameter;   
   uint256 minAmount;
   uint256 maxAmount;

   struct PaymentERC20 {
       uint256 amount;
       uint256 feeAmount;
       uint256 dueDate;
       uint256 wrapperSharesReceived;
       address payer;
       address payee;
       address feeAddress;
   }

   constructor(address _cometAddress, address _wrapperAddress, uint16 _feeModifier, uint256 _minDueDateParameter, uint256 _maxDueDateParameter, uint256 _minAmount, uint256 _maxAmount, uint8 _maxPayoutArraySize) {
       cometAddress = _cometAddress;
       baseAsset = IComet(cometAddress).baseToken();
       wrapperAddress = _wrapperAddress;
       feeModifier = _feeModifier;
       minDueDateParameter = _minDueDateParameter;	
       maxDueDateParameter = _maxDueDateParameter;
       minAmount = _minAmount;
       maxAmount = _maxAmount;
       maxPayoutArraySize = _maxPayoutArraySize;
       IComet(cometAddress).allow(wrapperAddress, true);
   }

   event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint256 dueDate, uint256 feeAmount, bytes paymentReference);
   event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference,uint256 feeAmount);
   event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);
   event ContractParametersUpdatedEvent(uint16 feeModifier, uint256 minDueDateParameter, uint256 maxDueDateParameter, uint256 minAmount, uint256 maxAmount, uint8 maxPayoutArraySize);

   /**
    * @notice paymentMapping keeps track of the paid invoices.
  */
   mapping(bytes => PaymentERC20) public paymentMapping;

   /**
    * @notice allowedRequestNetworkFeeAddresses makes sure ERC20 payments originating from the Request Network protocol go through the correct ERC20FeeProxy contract.
       This makes sure Request Network can detect the payment.
   */
   mapping(address => bool) public allowedRequestNetworkFeeAddresses;

   /**
    * @notice modifier only allows payer to use this function.
    */
   modifier OnlyPayer(bytes memory _paymentReference) {
       if(msg.sender != paymentMapping[_paymentReference].payer) revert NotAuthorized();
       _;
   }

   /**
   * @notice Make a payment using an ERC20 token.
   * @notice This function can't be used while it's paused.
   * @param _payee The receiver of the payment.
   * @param _feeAddress When using an additional fee, this is the address that will receive the _feeAmount.
   * @param _dueDate The due date of the payment, or invoice, in epoch time.
   * @param _amount The _asset amount in wei.
   * @param _feeAmount The total _asset fee amount in wei.
   * @param _paymentReference Reference of the related payment.
   * @dev Uses modifiers nonReentrant and whenNotPaused.
   * @dev The parameter _dueDate needs to be inserted in number of days (uint8).
   */

    function payInvoiceERC20(
        address _payee,
        address _feeAddress,
        uint256 _dueDate,
        uint256 _amount,
        uint256 _feeAmount,
        bytes calldata _paymentReference
        ) public nonReentrant whenNotPaused {

            if(_amount < minAmount || _amount > maxAmount) revert InvalidAmount();
            if(paymentMapping[_paymentReference].payer == msg.sender) revert PaymentReferenceInUse();
            if(paymentMapping[_paymentReference].payee == _payee) revert PaymentReferenceInUse();
            if(_payee == address(0)) revert ZeroAddressPayee();
            if(_feeAddress == address(0)) revert ZeroFeeAddress();
            if(_dueDate < block.timestamp + minDueDateParameter || _dueDate > block.timestamp + maxDueDateParameter) revert DueDateNotAllowed();            

            IERC20(baseAsset).safeTransferFrom(msg.sender, address(this), _amount + _feeAmount);
            IERC20(baseAsset).safeApprove(cometAddress, _amount + _feeAmount);

            uint256 cUsdcbalanceBeforeSupply = IERC20(cometAddress).balanceOf(address(this));
            IComet(cometAddress).supply(baseAsset, _amount + _feeAmount);
            uint256 cUsdcbalanceAfterSupply = IERC20(cometAddress).balanceOf(address(this));
            uint256 cUsdcAmountToWrap = cUsdcbalanceAfterSupply - cUsdcbalanceBeforeSupply;         

            uint256 wrappedShares = IWrapper(wrapperAddress).deposit(cUsdcAmountToWrap, address(this));

            paymentMapping[_paymentReference] = PaymentERC20(
                _amount,
                _feeAmount,
                _dueDate,
                wrappedShares,
                msg.sender,
                _payee,
                _feeAddress     
            );

            emit PaymentERC20Event(baseAsset, _payee, _feeAddress, _amount, _dueDate, _feeAmount, _paymentReference);         
    }

    /**                                                                             
    * @notice Allows the contract to pay payee (principal amount), payer (interest amount) and fee receiver (fee amount).
    This function cannot be paused.
    * @param payoutReferencesArray Insert the bytes array of references that need to be paid out.
    * @dev Uses modifier nonReentrant.
    **/
    function payOutERC20Invoice(bytes[] calldata payoutReferencesArray) external nonReentrant {

       uint256 i;
       uint256 payoutReferencesArrayLength = payoutReferencesArray.length;

       if(payoutReferencesArrayLength == 0 || payoutReferencesArrayLength > maxPayoutArraySize) revert InvalidArrayLength();

       for (; i < payoutReferencesArrayLength;) {
           bytes memory _paymentReference = payoutReferencesArray[i];
         if(paymentMapping[_paymentReference].amount == 0) revert NoPrePayment();
         if(paymentMapping[_paymentReference].dueDate > block.timestamp) revert ReferenceNotDue();

           address payable _payee = payable(paymentMapping[_paymentReference].payee);
           address payable _payer = payable(paymentMapping[_paymentReference].payer);
           address payable _feeAddress = payable(paymentMapping[_paymentReference].feeAddress);
           uint256 _amount = paymentMapping[_paymentReference].amount;
           uint256 _feeAmount = paymentMapping[_paymentReference].feeAmount;
           uint256 _wrapperSharesToRedeem = paymentMapping[_paymentReference].wrapperSharesReceived;

           paymentMapping[_paymentReference].amount = 0; //prevents double payout because of the require statement

           //redeem Wrapper shares and receive v3 cTokens
           IWrapper(wrapperAddress).redeem(_wrapperSharesToRedeem, address(this), address(this));

           //redeem all available v3 cTokens from Compound for baseAsset tokens
           uint256 cTokensToRedeem = IERC20(cometAddress).balanceOf(address(this));
           IComet(cometAddress).withdraw(baseAsset, cTokensToRedeem);

           //get new USDC balance
           uint256 _totalInterestGathered = IERC20(baseAsset).balanceOf(address(this)) - _amount;
           uint256 _interestAmount = _totalInterestGathered * feeModifier / 10000;

           if(allowedRequestNetworkFeeAddresses[_feeAddress] == true) {
               IERC20(baseAsset).safeApprove(ERC20FeeProxyAddress, _amount + _feeAmount);

               IERC20FeeProxy(ERC20FeeProxyAddress).transferFromWithReferenceAndFee(
                    baseAsset,
                    _payee,
                    _amount,
                    _paymentReference,
                    _feeAmount,
                    _feeAddress
               );

           } else {
               IERC20(baseAsset).safeTransfer(_payee, _amount);
               if(_feeAmount != 0) {
                    IERC20(baseAsset).safeTransfer(_feeAddress, _feeAmount);
               }
           }

           IERC20(baseAsset).safeTransfer(_payer, _interestAmount);
           ++i;

           emit PayOutERC20Event(baseAsset, _payee, _feeAddress, _amount, _paymentReference, _feeAmount);
           emit InterestPayoutEvent(baseAsset, _payer, _interestAmount, _paymentReference);
      }

   }

   function claimCompRewards() external onlyOwner {
       IWrapper(wrapperAddress).claimTo(owner());
   }

   function claimBaseAssetBalance() external onlyOwner {
       IERC20(baseAsset).safeTransfer(owner(), IERC20(baseAsset).balanceOf(address(this)));
   }

   function setContractParameters(uint16 _feeModifier, uint256 _minDueDateParameter, uint256 _maxDueDateParameter, uint256 _minAmount, uint256 _maxAmount, uint8 _maxPayoutArraySize) external onlyOwner {
         if(_feeModifier < 5000 || _feeModifier > 10000 ) revert InvalidFeeModifier();
         if(_minDueDateParameter < 5 * 86400) revert InvalidMinDueDate();
         if(_maxDueDateParameter > 365 * 86400) revert InvalidMaxDueDate();
         if(_minAmount < 1) revert InvalidMinAmount();
         if(_maxPayoutArraySize == 0) revert InvalidMaxArraySize();
         feeModifier = _feeModifier;
         minDueDateParameter = _minDueDateParameter;
         maxDueDateParameter = _maxDueDateParameter;
         minAmount = _minAmount;
         maxAmount = _maxAmount;
         maxPayoutArraySize = _maxPayoutArraySize;

         emit ContractParametersUpdatedEvent(feeModifier, minDueDateParameter, maxDueDateParameter, minAmount, maxAmount, maxPayoutArraySize);
   }

   function addRequestNetworkFeeAddress(address _requestNetworkFeeAddress) external onlyOwner {
       allowedRequestNetworkFeeAddresses[_requestNetworkFeeAddress] = true;
   }

   function setERC20FeeProxy(address _ERC20FeeProxyAddress) external onlyOwner {
       ERC20FeeProxyAddress = _ERC20FeeProxyAddress;
   }

   function pause() external onlyOwner {
       _pause();
   }

   function unpause() external onlyOwner {
       _unpause();
   }

}