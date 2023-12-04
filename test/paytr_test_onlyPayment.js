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
      "0x494e56332d32343999",
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

    })
});