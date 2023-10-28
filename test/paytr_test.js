var assert = require('assert');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const Paytr = artifacts.require("Paytr");
const {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, provider} = require('./helpers/parameters');

let amountToPay = 100 * (10**6);
let cometSupplyRateParam = web3.utils.toBN(10**18);

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });  
  
  it("should be able to make an ERC20 payment using USDC", async () => {
    const payee = accounts[6];

    //check supply rate
    let supplyRate = await CometContract.methods.getSupplyRate(cometSupplyRateParam).call();
    assert(supplyRate > 0);
    console.log(whaleAccount);

    await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});
    let wTokenBalanceBeforeTx = await wrapperContract.methods.balanceOf(instance.address).call();
    let contractCUSDCTokenBalanceBeforeTx = await cTokenContract.methods.balanceOf(instance.address).call();
    let whaleAccountBalanceBeforeTx = await USDCContract.methods.balanceOf(whaleAccount).call();
    
    let currentTime = await time.latest();
    let numberOfDaysToAdd = web3.utils.toBN(30);
    let dueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

    let payment = await instance.payInvoiceERC20(
      payee,
      whaleAccount, //dummy feeAddress
      dueDate,
      amountToPay,
      0, //no fee requires 0 as parameter input        
      "0x494e56332d32343034",
      {from: whaleAccount}
    );
    truffleAssert.eventEmitted(payment, "PaymentERC20Event");

    let contractCUSDCTokenBalanceAfterTx = await cTokenContract.methods.balanceOf(instance.address).call();
    let wTokenBalanceAfterTx = await wrapperContract.methods.balanceOf(instance.address).call();
    let expectedWhaleAccountBalanceAfterTx = web3.utils.toBN(whaleAccountBalanceBeforeTx).sub(web3.utils.toBN(amountToPay)).toString();
    let whaleAccountBalanceAfterTx = await USDCContract.methods.balanceOf(whaleAccount).call();

    assert.equal(whaleAccountBalanceAfterTx,expectedWhaleAccountBalanceAfterTx,"Whale account balance doens't match expected balance");
    assert.equal(contractCUSDCTokenBalanceBeforeTx, contractCUSDCTokenBalanceAfterTx,"Contract cToken balance doesn't match");
    assert(wTokenBalanceAfterTx > wTokenBalanceBeforeTx, "wToken balance hasn't changed");

    //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
    let currentBlock = await web3.eth.getBlockNumber();
    await provider.request({method: 'evm_increaseTime', params: [10000000]});
    await time.advanceBlockTo(currentBlock + 999); //999 + 1 block

    //test redeem
    let contractUSDCTokenBalanceBeforeRedeeming = await USDCContract.methods.balanceOf(instance.address).call();
    let contractCUSDCTokenBalanceBeforeRedeeming = await cTokenContract.methods.balanceOf(instance.address).call();
    let payeeUSDCBalanceBeforePayout = await USDCContract.methods.balanceOf(accounts[6]).call();

    //create array with payment references to redeem
    let redeemArray = [];
    redeemArray.push("0x494e56332d32343034");

    //test payout
    await instance.payOutERC20Invoice(redeemArray);

    let contractCUSDCTokenBalanceAfterRedeeming = await cTokenContract.methods.balanceOf(instance.address).call();
    let contractUSDCTokenBalanceAfterRedeeming = await USDCContract.methods.balanceOf(instance.address).call();
    let wTokenBalanceAfterRedeeming = await wrapperContract.methods.balanceOf(instance.address).call();

    let payeeUSDCBalanceAfterPayout = await USDCContract.methods.balanceOf(accounts[6]).call();
    let expectedPayeeUSDCBalanceAfterPayout = web3.utils.toBN(payeeUSDCBalanceBeforePayout).add(web3.utils.toBN(amountToPay));
    let whaleAccountBalanceAfterInterestPayout = await USDCContract.methods.balanceOf(whaleAccount).call();
    assert(whaleAccountBalanceAfterInterestPayout> whaleAccountBalanceAfterTx,"Wrong whale balance after payout");
    assert.equal(expectedPayeeUSDCBalanceAfterPayout, payeeUSDCBalanceAfterPayout,"Payee USDC balance doesn't match");
    assert.equal(contractCUSDCTokenBalanceAfterRedeeming,0,"Contract's cToken balance != 0");
    assert(contractUSDCTokenBalanceBeforeRedeeming < contractUSDCTokenBalanceAfterRedeeming,"Contract USDC balance didn't increase");
    assert.equal(contractCUSDCTokenBalanceBeforeRedeeming, contractCUSDCTokenBalanceAfterRedeeming,"Contract cToken balance doesn't match");
    assert(wTokenBalanceAfterRedeeming < 1, "Wrong wrapped token balance;");

  });

});