var assert = require('assert');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const Paytr = artifacts.require("Paytr");
const {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, provider} = require('./helpers/parameters');

let amountToPayInv1 = 150000000; //150 USDC
let amountToPayInv2 = 70000000; //70 USDC
let cometSupplyRateParam = web3.utils.toBN(10**18);

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });
  
  describe("Normal payment-redeem flow for 2 invoices", () => {
    it("should be able to make multiple USDC payments and redeem them all in go (all invoices are due)", async () => {
      const payeeInv1 = accounts[6];
      const payeeInv2 = accounts[6];

      let payeeUSDCBalanceInitial = await USDCContract.methods.balanceOf(accounts[6]).call();
      let currentTime = await time.latest();
      let numberOfDaysToAdd = web3.utils.toBN(8);
      let dueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

      //check supply rate
      let supplyRate = await CometContract.methods.getSupplyRate(cometSupplyRateParam).call();
      assert(supplyRate > 0);

      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});

      let cUSDCTokenBalanceBeforeTx1 = await cTokenContract.methods.balanceOf(instance.address).call();
      let wTokenBalanceBeforeTx1 = await wrapperContract.methods.balanceOf(instance.address).call();
      let whaleAccountBalanceBeforeTx1 = await USDCContract.methods.balanceOf(whaleAccount).call();
      //payment invoice 1 ref. 0x494e56332d32343001
      await instance.payInvoiceERC20(
        payeeInv1,
        whaleAccount,
        dueDate,
        amountToPayInv1,
        0,
        "0x494e56332d32343001",
        {from: whaleAccount}
      );

      let cUSDCTokenBalanceAfterTx1 = await cTokenContract.methods.balanceOf(instance.address).call();
      let wTokenBalanceAfterTx1 = await wrapperContract.methods.balanceOf(instance.address).call();
      let expectedWhaleAccountBalanceAfterTx1 = web3.utils.toBN(whaleAccountBalanceBeforeTx1).sub(web3.utils.toBN(amountToPayInv1)).toString();
      let whaleAccountBalanceAfterTx1 = await USDCContract.methods.balanceOf(whaleAccount).call();

      assert.equal(cUSDCTokenBalanceBeforeTx1,cUSDCTokenBalanceAfterTx1,"cUSDC token balance should match because it get's (un)wrapped");
      assert.equal(whaleAccountBalanceAfterTx1, expectedWhaleAccountBalanceAfterTx1,"Whale account balance doens't match expected balance after tx1");
      assert(wTokenBalanceAfterTx1 > wTokenBalanceBeforeTx1, "wToken balance hasn't changed after tx1");

      let cUSDCTokenBalanceBeforeTx2 = await cTokenContract.methods.balanceOf(instance.address).call();
      let wTokenBalanceBeforeTx2 = await wrapperContract.methods.balanceOf(instance.address).call();
      let whaleAccountBalanceBeforeTx2 = await USDCContract.methods.balanceOf(whaleAccount).call();
      //payment invoice 2 ref. 0x494e56332d32343002
      await instance.payInvoiceERC20(
        payeeInv2,
        whaleAccount,
        dueDate,
        amountToPayInv2,
        0,
        "0x494e56332d32343002",
        {from: whaleAccount}
      );

      //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
      let currentBlockTx1 = await web3.eth.getBlockNumber();
      await provider.request({method: 'evm_increaseTime', params: [10000000]});
      await time.advanceBlockTo(currentBlockTx1 + 999); //999 + 1 block

      let cUSDCTokenBalanceAfterTx2 = await cTokenContract.methods.balanceOf(instance.address).call();
      let wTokenBalanceAfterTx2 = await wrapperContract.methods.balanceOf(instance.address).call();
      let expectedWhaleAccountBalanceAfterTx2 = web3.utils.toBN(whaleAccountBalanceBeforeTx2).sub(web3.utils.toBN(amountToPayInv2)).toString();
      let whaleAccountBalanceAfterTx2 = await USDCContract.methods.balanceOf(whaleAccount).call();

      assert.equal(cUSDCTokenBalanceBeforeTx2,cUSDCTokenBalanceAfterTx2,"cUSDC token balance should match because it get's (un)wrapped");
      assert.equal(whaleAccountBalanceAfterTx2,expectedWhaleAccountBalanceAfterTx2,"Whale account balance doensn't match expected balance after tx2");
      assert(wTokenBalanceAfterTx2 > wTokenBalanceBeforeTx2, "wToken balance hasn't changed");

      //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
      let currentBlockTx2 = await web3.eth.getBlockNumber();
      await provider.request({method: 'evm_increaseTime', params: [10000000]});
      await time.advanceBlockTo(currentBlockTx2 + 999); //999 + 1 block

      //test redeem
      let cUSDCTokenBalanceBeforeRedeemingFromCompound = await cTokenContract.methods.balanceOf(instance.address).call();
      let USDCTokenBalanceBeforeRedeemingFromCompound = await USDCContract.methods.balanceOf(instance.address).call();

      assert(cUSDCTokenBalanceBeforeRedeemingFromCompound == 0, "cUSDC token balance should be 0");
      assert(USDCTokenBalanceBeforeRedeemingFromCompound == 0, "USDC token balance should be 0");

      //create array with payment references to redeem
      let redeemArray = ["0x494e56332d32343001","0x494e56332d32343002"];

      //redeem from Compound and pay all invoices + interest
      await instance.payOutERC20Invoice(redeemArray);

      let cUSDCTokenBalanceAfterRedeemingFromCompound = await cTokenContract.methods.balanceOf(instance.address).call();
      let USDCTokenBalanceAfterRedeemingFromCompound = await USDCContract.methods.balanceOf(instance.address).call();
      let wTokenBalanceAfterRedeemingFromCompound = await wrapperContract.methods.balanceOf(instance.address).call();
      let payeeUSDCBalance = await USDCContract.methods.balanceOf(payeeInv1).call();
      let whaleAccountBalanceAfterInterestPayout = await USDCContract.methods.balanceOf(whaleAccount).call();
      let expectedPayeeUSDCBalanceAfterPayout = (web3.utils.toBN(payeeUSDCBalanceInitial).add(web3.utils.toBN(amountToPayInv1)).add(web3.utils.toBN(amountToPayInv2))).toString();
      console.log("Expected:",expectedPayeeUSDCBalanceAfterPayout);
      console.log("Payee balance:",payeeUSDCBalance);
      assert(cUSDCTokenBalanceAfterRedeemingFromCompound == 0, "cUSDC token balance should be 0");
      assert(USDCTokenBalanceBeforeRedeemingFromCompound < USDCTokenBalanceAfterRedeemingFromCompound, "Contract's USDC balance doesn't match");
      assert(wTokenBalanceAfterRedeemingFromCompound <= 1, "Contract wToken balance > 1");
      assert(whaleAccountBalanceAfterInterestPayout > whaleAccountBalanceAfterTx2,"Wrong whale balance after interest payout");
      assert.equal(expectedPayeeUSDCBalanceAfterPayout, payeeUSDCBalance,"Payee USDC balance mismatch");

   });
  });

});