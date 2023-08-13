// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/Utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
 
 
interface IComet {
    function supply(address asset, uint amount) external;
    function withdraw(address asset, uint amount) external;
    function baseToken() external view returns (address);
    function allow(address manager, bool isAllowed) external;
}
 
interface ICometRewards {
  function claimTo(address comet, address src, address to, bool shouldAccrue) external;
}
 
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
}
 
/**
* @title   Paytr
* @notice  Paytr allows you to earn by paying early.
*/
 
contract Paytr is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
 
    address baseAsset;
    address ERC20FeeProxyAddress;
    address wrapperAddress;
    address cometAddress;
    uint8 minDueDateInDays;
    uint8 maxPayoutArraySize;
    uint16 feeModifier;
    uint16 maxDueDateInDays;    
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
 
    constructor(address _cometAddress, address _wrapperAddress, address _ERC20FeeProxyAddress, uint16 _feeModifier, uint8 _minDueDateInDays, uint16 _maxDueDateInDays, uint256 _minAmount, uint256 _maxAmount, uint8 _maxPayoutArraySize) {
        cometAddress = _cometAddress;
        baseAsset = IComet(cometAddress).baseToken();
        wrapperAddress = _wrapperAddress;
        ERC20FeeProxyAddress = _ERC20FeeProxyAddress;
        feeModifier = _feeModifier;
        minDueDateInDays = _minDueDateInDays;
        maxDueDateInDays = _maxDueDateInDays;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        maxPayoutArraySize = _maxPayoutArraySize;
    }
 
    event PaymentERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, uint256 dueDate, uint256 feeAmount, bytes paymentReference);
    event PayOutERC20Event(address tokenAddress, address payee, address feeAddress, uint256 amount, bytes paymentReference,uint256 feeAmount);
    event InterestPayoutEvent(address tokenAddress, address payee, uint256 interestAmount, bytes paymentReference);
    event DueDateUpdatedEvent(address payer, address payee, bytes paymentReference, uint256 dueDate);
    event ContractParametersUpdatedEvent(uint16 feeModifier, uint8 minDueDateInDays, uint16 maxDueDateInDays, uint256 minAmount, uint256 maxAmount, uint8 maxPayoutArraySize); 
 
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
        require(msg.sender == paymentMapping[_paymentReference].payer, "Not Authorized");
        _;
    }
 
     /**
    * @notice modifier checks if payment is present in contract.
    */
    modifier IsInContract(bytes memory _paymentReference) {      
        require(paymentMapping[_paymentReference].amount != 0, "No prepayment found");
        _;
    }
 
    /**
    * @notice Make a payment using an ERC20 token.
    * @notice This function can't be used while it's paused.
    * @param _payee The receiver of the payment.
    * @param _feeAddress When using an additional fee, this is the address that will receive the _feeAmount.
    * @param _dueInDays The due date of the payment, or invoice, in days.
    * @param _amount The _asset amount in wei.
    * @param _feeAmount The total _asset fee amount in wei.
    * @param _paymentReference Reference of the related payment.
    * @dev Uses modifiers nonReentrant and whenNotPaused.
    * @dev The parameter _dueDate needs to be inserted in number of days (uint8).
    */
 
    function payInvoiceERC20(
        address _payee,
        address _feeAddress,
        uint8 _dueInDays,
        uint256 _amount,
        uint256 _feeAmount,
        bytes calldata _paymentReference
        ) public nonReentrant whenNotPaused {
            
            require(_amount != 0, "0 Amount");
            require(_amount >= minAmount, "Amount too low");
            require(paymentMapping[_paymentReference].payer != msg.sender,"Payment reference already used");
            require(paymentMapping[_paymentReference].payee != _payee,"Payment reference already used");
            require(_payee != address(0), "Payee is 0 address");
            require(_feeAddress != address(0), "Fee address is 0 address");
            if(_dueInDays != 0) {
                require(_dueInDays <= maxDueDateInDays && _dueInDays >= minDueDateInDays,"Due date not allowed on payment");
            }

            uint256 dueDate;
 
            _dueInDays != 0 ? dueDate = block.timestamp + _dueInDays * 1 days : dueDate = _dueInDays;
 
            IERC20(baseAsset).safeTransferFrom(msg.sender, address(this), _amount + _feeAmount);
            IERC20(baseAsset).safeApprove(cometAddress, _amount + _feeAmount);
            IComet(cometAddress).allow(wrapperAddress, true);
 
            uint256 cUsdcbalanceBeforeSupply = IERC20(cometAddress).balanceOf(address(this));
            IComet(cometAddress).supply(baseAsset, _amount + _feeAmount);
            uint256 cUsdcbalanceAfterSupply = IERC20(cometAddress).balanceOf(address(this));
            uint256 cUsdcAmountToWrap = cUsdcbalanceAfterSupply - cUsdcbalanceBeforeSupply;
          
            uint256 wrappedBalanceBeforeSupply = IERC20(wrapperAddress).balanceOf(address(this));          
            IWrapper(wrapperAddress).deposit(cUsdcAmountToWrap, address(this));
            uint256 wrappedBalanceAfterSupply = IERC20(wrapperAddress).balanceOf(address(this));
            uint256 wrappedShares = wrappedBalanceAfterSupply - wrappedBalanceBeforeSupply;
     
            paymentMapping[_paymentReference] = PaymentERC20(
                _amount,
                _feeAmount,
                dueDate,
                wrappedShares,
                msg.sender,
                _payee,
                _feeAddress      
            );
 
            emit PaymentERC20Event(baseAsset, _payee, _feeAddress, _amount, dueDate, _feeAmount, _paymentReference);          
    }
 
    /**
    * @notice This function allows the payer to update the due date of the payment. This is only possible when the initial payment had a '0' dueDate,
   for example when using the Paytr contract for escrow or crowdfunding. Updating the due date means releasing the funds in the future.
    * @param _paymentReference Input the paymentReference in bytes.
    * @param _dueDateUpdated Input the due date in epoch time format.
    * @dev Uses modifiers OnlyPayer and nonReentrant;
    */  
    
    function updateDueDate(bytes calldata _paymentReference, uint256 _dueDateUpdated) public IsInContract(_paymentReference) OnlyPayer(_paymentReference) nonReentrant{
        require(paymentMapping[_paymentReference].dueDate == 0, "New due date != 0");
        require(_dueDateUpdated > block.timestamp + 1200 && _dueDateUpdated <= block.timestamp + (maxDueDateInDays * 86400), "Invalid new due date");
        paymentMapping[_paymentReference].dueDate = _dueDateUpdated;
        address _payee = paymentMapping[_paymentReference].payee;
 
        emit DueDateUpdatedEvent(msg.sender, _payee, _paymentReference, _dueDateUpdated);
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
 
        require(payoutReferencesArrayLength != 0 && payoutReferencesArrayLength <= maxPayoutArraySize, "Invalid array length");
 
        for (; i < payoutReferencesArrayLength;) {
            bytes memory _paymentReference = payoutReferencesArray[i];
            require(paymentMapping[_paymentReference].amount != 0,"Unknown payment reference"); //check to see if payment reference to be paid out is present in the contract
            require(paymentMapping[_paymentReference].dueDate <= block.timestamp,"Reference not due yet");
 
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
            uint256 _interestAmount = _totalInterestGathered * (10000 - (feeModifier*100)) / 10000;
 
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
        ICometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40).claimTo(cometAddress, address(this), owner(), true);
    }
 
    function claimBaseAssetBalance() external onlyOwner {
        IERC20(baseAsset).safeTransfer(owner(), IERC20(baseAsset).balanceOf(address(this)));
    }
 
    function setContractParameters(uint16 _feeModifier, uint8 _minDueDateInDays, uint16 _maxDueDateInDays, uint256 _minAmount, uint256 _maxAmount, uint8 _maxPayoutArraySize) external onlyOwner {
          require(_feeModifier <= 50, "Invalid feeModifier");
          require(_minDueDateInDays >=5, "Invalid min. due date");
          require(_maxDueDateInDays <=365, "Invalid max. due date");
          require(_minAmount >= 1, "Invalid min. amount");
          require(_maxPayoutArraySize != 0, "Invalid max array size");
          feeModifier = _feeModifier;
          minDueDateInDays = _minDueDateInDays;
          maxDueDateInDays = _maxDueDateInDays;
          minAmount = _minAmount;
          maxAmount = _maxAmount;
          maxPayoutArraySize = _maxPayoutArraySize;

          emit ContractParametersUpdatedEvent(feeModifier, minDueDateInDays, maxDueDateInDays, minAmount, maxAmount, maxPayoutArraySize);
    }
         
 
    function addRequestNetworkFeeAddress(address _requestNetworkFeeAddress) external onlyOwner {
        allowedRequestNetworkFeeAddresses[_requestNetworkFeeAddress] = true;
    }
 
    function setERC20FeeProxy(address _ERC20FeeProxyAddress) external onlyOwner {
        ERC20FeeProxyAddress = _ERC20FeeProxyAddress;
    }
 
    function disallowWrapper() external onlyOwner {
        IComet(cometAddress).allow(wrapperAddress, false);
    }
 
    function pause() external onlyOwner {
        _pause();
    }
 
    function unpause() external onlyOwner {
        _unpause();
    }
 
}