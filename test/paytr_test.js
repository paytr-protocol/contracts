var assert = require('assert');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const Paytr = artifacts.require("Paytr");
const {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, provider} = require('./helpers/parameters');

let amountToPay = 150000000;
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
    console.log("Supply rate: ",supplyRate);

    await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});
    let wTokenBalanceBeforeTx = await wrapperContract.methods.balanceOf(instance.address).call();
    console.log("WrappedToken balance before tx: ",wTokenBalanceBeforeTx);

    let whaleAccountBalanceBeforeTx = await USDCContract.methods.balanceOf(whaleAccount).call();

    let payment = await instance.payInvoiceERC20(
      payee,
      whaleAccount, //dummy feeAddress
      7,
      amountToPay,
      0, //no fee requires 0 as parameter input        
      "0x494e56332d32343034",
      {from: whaleAccount}
    );
    truffleAssert.eventEmitted(payment, 'PaymentERC20Event');

    let cUSDCTokenBalanceAfterTx = await cTokenContract.methods.balanceOf(instance.address).call();
    console.log("cToken balance after tx :",cUSDCTokenBalanceAfterTx);
    let wTokenBalanceAfterTx = await wrapperContract.methods.balanceOf(instance.address).call();
    console.log("WrappedToken balance after tx: ",wTokenBalanceAfterTx);
    let expectedWhaleAccountBalanceAfterTx = web3.utils.toBN(whaleAccountBalanceBeforeTx).sub(web3.utils.toBN(amountToPay)).toString();
    let whaleAccountBalanceAfterTx = await USDCContract.methods.balanceOf(whaleAccount).call();

    assert.equal(whaleAccountBalanceAfterTx,expectedWhaleAccountBalanceAfterTx,"Whale account balance doens't match expected balance");
    assert(wTokenBalanceAfterTx > wTokenBalanceBeforeTx, "wToken balance hasn't changed");

    //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
    let currentBlock = await web3.eth.getBlockNumber();
    console.log("...");
    console.log("Increasing time and blocks to gather interest...");
    await provider.request({method: 'evm_increaseTime', params: [10000000]});
    await time.advanceBlockTo(currentBlock + 999); //999 + 1 block
    console.log("Increased time with 10000000 seconds, advanced 1000 blocks");
    console.log("...");

    //test redeem
    let USDCTokenBalanceBeforeRedeeming = await USDCContract.methods.balanceOf(instance.address).call();
    console.log("USDC balance before redeeming: ",USDCTokenBalanceBeforeRedeeming);
    let cUSDCTokenBalanceBeforeRedeeming = await cTokenContract.methods.balanceOf(instance.address).call();
    console.log("cToken balance before redeeming: ",cUSDCTokenBalanceBeforeRedeeming);

    //create array with payment references to redeem
    let redeemArray = [];
    redeemArray.push("0x494e56332d32343034");

    //test redeem from Compound
    await instance.payOutERC20Invoice(redeemArray);


    let cUSDCTokenBalanceAfterRedeemingFromCompound = await cTokenContract.methods.balanceOf(instance.address).call();
    console.log("Contract's cToken balance after redeeming from Compound: ",cUSDCTokenBalanceAfterRedeemingFromCompound);
    let USDCTokenBalanceAfterRedeemingFromCompound = await USDCContract.methods.balanceOf(instance.address).call();
    console.log("Contract's USDC balance after redeeming from Compound: ",USDCTokenBalanceAfterRedeemingFromCompound);
    let wTokenBalanceAfterRedeemingFromCompound = await wrapperContract.methods.balanceOf(instance.address).call();
    console.log("Contract's WrappedToken balance after redeeming from Compound: ",wTokenBalanceAfterRedeemingFromCompound);

    let payeeUSDCBalance = await USDCContract.methods.balanceOf(accounts[6]).call();
    console.log("Payee USDC balance: ",payeeUSDCBalance);
    let whaleAccountBalanceAfterInterestPayout = await USDCContract.methods.balanceOf(whaleAccount).call();
    console.log("Whale balance after tx: ",whaleAccountBalanceAfterTx);
    console.log("Whale balance after interest payout: ",whaleAccountBalanceAfterInterestPayout);
    assert(whaleAccountBalanceAfterInterestPayout> whaleAccountBalanceAfterTx,"Wrong whale balance after payout");

  });

});