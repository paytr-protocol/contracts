var assert = require('assert');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const Paytr = artifacts.require("Paytr");
const {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, compTokenContract, provider} = require('./helpers/parameters');

let amountToPay = 45_000 * 10**6; //45k USDC
let cometSupplyRateParam = web3.utils.toBN(10**18);

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });
  
    it("should be able to make an ERC20 payment of 45,000 USDC", async () => { //and claim $COMP rewards", async () => {
    const payee = accounts[6];

    //check supply rate
    let supplyRate = await CometContract.methods.getSupplyRate(cometSupplyRateParam).call();
    assert(supplyRate > 0);
    let currentTime = await time.latest();
    let numberOfDaysToAdd = web3.utils.toBN(30);
    let dueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

    await USDCContract.methods.approve(instance.address, 100000000000000).send({from: whaleAccount});

    //contract balances
    let contractWTokenBalanceBeforeTx = await wrapperContract.methods.balanceOf(instance.address).call();
    let contractUSDCBalanceBeforeTx = await USDCContract.methods.balanceOf(instance.address).call();
    let contractCTokenBalanceBeforeTx = await cTokenContract.methods.balanceOf(instance.address).call();

    //whale balances
    let whaleUSDCBalanceBeforeTx = await USDCContract.methods.balanceOf(whaleAccount).call();
    let whaleCTokenBalanceBeforeTx = await cTokenContract.methods.balanceOf(instance.address).call();
    
    //payee balances
    let payeeUSDCBalanceBeforeTx = await USDCContract.methods.balanceOf(payee).call();      

    let payment = await instance.payInvoiceERC20(
      payee,
      whaleAccount, //dummy feeAddress
      dueDate,
      amountToPay,
      0, //no fee requires 0 as parameter input        
      "0x494e56332d32343034",
      {from: whaleAccount}
    );

    //contract balances
    let contractWTokenBalanceAfterTx = await wrapperContract.methods.balanceOf(instance.address).call();
    let contractUSDCBalanceAfterTx = await USDCContract.methods.balanceOf(instance.address).call();
    let contractCTokenBalanceAfterTx = await cTokenContract.methods.balanceOf(instance.address).call();

    //whale balances
    let whaleUSDCBalanceAfterTx = await USDCContract.methods.balanceOf(whaleAccount).call();
    let whaleCTokenBalanceAfterTx = await cTokenContract.methods.balanceOf(instance.address).call();
    let expectedWhaleUSDCBalanceAfterTx = web3.utils.toBN(whaleUSDCBalanceBeforeTx).sub(web3.utils.toBN(amountToPay)).toString();
    
    //payee balances
    let payeeUSDCBalanceAfterTx = await USDCContract.methods.balanceOf(payee).call();
    
    assert.equal(contractUSDCBalanceBeforeTx,contractUSDCBalanceAfterTx,"contract USDC balance doesn't match");
    assert.equal(contractCTokenBalanceBeforeTx, contractCTokenBalanceAfterTx,"contract cToken balance doesn't match");
    assert.equal(whaleUSDCBalanceAfterTx,expectedWhaleUSDCBalanceAfterTx,"Whale USDC balance doesn't match expected balance");
    assert.equal(whaleCTokenBalanceBeforeTx, whaleCTokenBalanceAfterTx,"Whale cToken balance doesn't match expected balance");
    assert(contractWTokenBalanceAfterTx > contractWTokenBalanceBeforeTx,"wToken balance hasn't changed");
    assert.equal(payeeUSDCBalanceAfterTx, payeeUSDCBalanceBeforeTx,"Payee USDC balance doesn't match");

    truffleAssert.eventEmitted(payment, "PaymentERC20Event");

    //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
    let currentBlock = await web3.eth.getBlockNumber();
    await provider.request({method: 'evm_increaseTime', params: [10000000]});
    await time.advanceBlockTo(currentBlock + 999); //999 + 1 block

    //create array with payment references to pay
    let redeemArray = [];
    redeemArray.push("0x494e56332d32343034");

    //redeem from Compound and pay everyone
    let contractUSDCBalanceBeforePayOut = await USDCContract.methods.balanceOf(instance.address).call();
    let contractWrapperBalanceBeforePayOut = await wrapperContract.methods.balanceOf(instance.address).call();
    let contractCTokenBalanceBeforePayOut = await cTokenContract.methods.balanceOf(instance.address).call();
    let payeeUSDCBalanceBeforePayOut = await USDCContract.methods.balanceOf(payee).call();

    let payout = await instance.payOutERC20Invoice(redeemArray);

    let contractUSDCBalanceAfterPayOut = await USDCContract.methods.balanceOf(instance.address).call();
    let contractWrapperBalanceAfterPayOut = await wrapperContract.methods.balanceOf(instance.address).call();
    let contractCTokenBalanceAfterPayOut = await cTokenContract.methods.balanceOf(instance.address).call();
    let payeeUSDCBalanceAfterPayOut = await USDCContract.methods.balanceOf(payee).call();
    let whaleAccountBalanceAfterPayOut = await USDCContract.methods.balanceOf(whaleAccount).call();

    assert(contractUSDCBalanceAfterPayOut > contractUSDCBalanceBeforePayOut,"Wrong contract USDC balance after payout");
    assert(contractWrapperBalanceAfterPayOut < contractWrapperBalanceBeforePayOut,"Wrong contract Wrapper balance after payout");
    assert(whaleAccountBalanceAfterPayOut > whaleUSDCBalanceAfterTx,"Wrong whale balance after payout");
    assert.equal(contractCTokenBalanceAfterPayOut,contractCTokenBalanceBeforePayOut,"Wrong contract cToken balance after payout, it should be equal because the tokens are wrapped and unwrapped");
    assert(payeeUSDCBalanceAfterPayOut > payeeUSDCBalanceBeforePayOut,"Wrong payee USDC balance after payout");

    truffleAssert.eventEmitted(payout, "PayOutERC20Event");
    truffleAssert.eventEmitted(payout, "InterestPayoutEvent");

    //transfer USDC contract balance to owner
    let ownerUSDCBalanceBeforeClaimingBaseAsset = await USDCContract.methods.balanceOf(accounts[0]).call();
    await instance.claimBaseAssetBalance();
    let ownerUSDCBalanceAfterClaimingBaseAsset = await USDCContract.methods.balanceOf(accounts[0]).call();
    assert(ownerUSDCBalanceBeforeClaimingBaseAsset < ownerUSDCBalanceAfterClaimingBaseAsset,"Owner USDC balance doesn't match");

    let contractUSDCBalanceAfterBalanceTransfer = await USDCContract.methods.balanceOf(instance.address).call();
    assert(contractUSDCBalanceAfterBalanceTransfer < contractUSDCBalanceAfterPayOut, "contract USDC balance doesn't match");
    assert(contractUSDCBalanceAfterBalanceTransfer == 0, "contract USDC balance should be 0");

    // let ownerCompBalanceBeforeClaiming = await compTokenContract.methods.balanceOf(accounts[0]).call();
    // await instance.claimCompRewards();
    // let ownerCompBalanceAfterClaiming = await compTokenContract.methods.balanceOf(accounts[0]).call();
    // assert(ownerCompBalanceAfterClaiming > ownerCompBalanceBeforeClaiming, "$COMP balance didn't increase");

  });

});