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
  
  it("shouldn't be able to use a duplicate payment reference with identical payer and payee", async () => {
    const payee = accounts[6];

    //check supply rate
    let supplyRate = await CometContract.methods.getSupplyRate(cometSupplyRateParam).call();
    assert(supplyRate > 0);

    let currentTime = await time.latest();
    let numberOfDaysToAdd = web3.utils.toBN(30);
    let dueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

    await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});
    let wTokenBalanceBeforeTx = await wrapperContract.methods.balanceOf(instance.address).call();
    let contractCUSDCTokenBalanceBeforeTx = await cTokenContract.methods.balanceOf(instance.address).call();
    let whaleAccountBalanceBeforeTx = await USDCContract.methods.balanceOf(whaleAccount).call();

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

    await truffleAssert.fails(instance.payInvoiceERC20(
      payee,
      whaleAccount,
      dueDate,
      amountToPay,
      0,       
      "0x494e56332d32343034",
      {from: whaleAccount}
    ));
  });

    it("shouldn't be able to use a duplicate payment reference with identical payee but different payer", async () => {
      const payee = accounts[6];
  
      await USDCContract.methods.transfer(accounts[4], amountToPay).send({from: whaleAccount});

      let currentTime = await time.latest();
      let numberOfDaysToAdd = web3.utils.toBN(30);
      let dueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();
  
      await truffleAssert.fails(instance.payInvoiceERC20(
        payee,
        whaleAccount,
        dueDate,
        amountToPay,
        0,      
        "0x494e56332d32343034",
        {from: accounts[4]}
      ));

  });

  it("shouldn't be able to use a duplicate payment reference when the payment reference hasn't been redeemed yet", async () => {
    const payee2 = accounts[8];
    await USDCContract.methods.approve(instance.address, amountToPay).send({from: accounts[4]});

    let currentTime = await time.latest();
    let numberOfDaysToAdd = web3.utils.toBN(30);
    let dueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

    await truffleAssert.fails(instance.payInvoiceERC20(
      payee2,
      whaleAccount,
      dueDate,
      amountToPay,
      0,      
      "0x494e56332d32343034",
      {from: accounts[4]}
    ));

  });

  it("should be able to use a duplicate payment reference when the payment reference has been redeemed and the payee is different", async () => {
    //check supply rate
    let supplyRate = await CometContract.methods.getSupplyRate(cometSupplyRateParam).call();
    assert(supplyRate > 0);
    const payee2 = accounts[8];
    const payee3 = accounts[9];

    await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});

    let currentTimeTx1 = await time.latest();
    let numberOfDaysToAddTx1 = web3.utils.toBN(30);
    let dueDateTx1 = web3.utils.toBN(currentTimeTx1).add((numberOfDaysToAddTx1).mul(web3.utils.toBN(86400))).toString();

    let paymentTx1 = await instance.payInvoiceERC20(
      payee2,
      whaleAccount,
      dueDateTx1,
      amountToPay,
      0,      
      "0x494e56332d32340001",
      {from: whaleAccount}
    );
    truffleAssert.eventEmitted(paymentTx1, "PaymentERC20Event");
    //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
    let currentBlock = await web3.eth.getBlockNumber();
    await provider.request({method: 'evm_increaseTime', params: [10000000]});
    await time.advanceBlockTo(currentBlock + 999); //999 + 1 block

    //create array with payment references to redeem
    let redeemArray = [];
    redeemArray.push("0x494e56332d32340001");

    //test payout
    await instance.payOutERC20Invoice(redeemArray);

    let currentTimeTx2 = await time.latest();
    let numberOfDaysToAddTx2 = web3.utils.toBN(30);
    let dueDateTx2 = web3.utils.toBN(currentTimeTx2).add((numberOfDaysToAddTx2).mul(web3.utils.toBN(86400))).toString();

    let paymentTx2 = await instance.payInvoiceERC20(
      payee3,
      whaleAccount,
      dueDateTx2,
      amountToPay,
      0,      
      "0x494e56332d32340001",
      {from: whaleAccount}
    );
    truffleAssert.eventEmitted(paymentTx2, "PaymentERC20Event");

  });

});