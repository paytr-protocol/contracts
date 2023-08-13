var assert = require('assert');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const Paytr = artifacts.require("Paytr");
const {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, provider} = require('./helpers/parameters');

let amountToPayInv1 = 150000000; //150 USDC
let amountToPayInv2 = 70000000; //70 USDC
//let amountToPayInv3 = 300000000; //300 USDC
let cometSupplyRateParam = web3.utils.toBN(10**18);

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });
  
  describe("Normal payment-redeem flow for 3 invoices", () => {
    it("should be able to make multiple USDC payments and redeem them all in go (all invoices are due)", async () => {
      const payeeInv1 = accounts[6];
      const payeeInv2 = accounts[6];
      //const payeeInv3 = accounts[8];

      let payeeUSDCBalanceInitial = await USDCContract.methods.balanceOf(accounts[6]).call();
      console.log("Payee's balance before starting the test: ", payeeUSDCBalanceInitial);

      //check supply rate
      let supplyRate = await CometContract.methods.getSupplyRate(cometSupplyRateParam).call();
      assert(supplyRate > 0);
      console.log("Supply rate: ",supplyRate);

      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});
      let wTokenBalanceBeforeTx1 = await wrapperContract.methods.balanceOf(instance.address).call();
      console.log("WrappedToken balance before tx1: ",wTokenBalanceBeforeTx1);

      let whaleAccountBalanceBeforeTx1 = await USDCContract.methods.balanceOf(whaleAccount).call();
      //payment invoice 1 ref. 0x494e56332d32343001
      await instance.payInvoiceERC20(
        payeeInv1,
        whaleAccount,
        7,
        amountToPayInv1,
        0,
        "0x494e56332d32343001",
        {from: whaleAccount}
      );

      let cUSDCTokenBalanceAfterTx1 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log("cToken balance after tx1 :",cUSDCTokenBalanceAfterTx1);
      let wTokenBalanceAfterTx1 = await wrapperContract.methods.balanceOf(instance.address).call();
      console.log("WrappedToken balance after tx1: ",wTokenBalanceAfterTx1);
      let expectedWhaleAccountBalanceAfterTx1 = web3.utils.toBN(whaleAccountBalanceBeforeTx1).sub(web3.utils.toBN(amountToPayInv1)).toString();
      let whaleAccountBalanceAfterTx1 = await USDCContract.methods.balanceOf(whaleAccount).call();

      assert.equal(whaleAccountBalanceAfterTx1,expectedWhaleAccountBalanceAfterTx1,"Whale account balance doens't match expected balance after tx1");
      assert(wTokenBalanceAfterTx1 > wTokenBalanceBeforeTx1, "wToken balance hasn't changed after tx1");

      //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
      let currentBlockTx1 = await web3.eth.getBlockNumber();
      console.log("...");
      console.log("Increasing time and blocks to gather interest after tx1...");
      await provider.request({method: 'evm_increaseTime', params: [10000000]});
      await time.advanceBlockTo(currentBlockTx1 + 999); //999 + 1 block
      console.log("Increased time with 10000000 seconds, advanced 1000 blocks");
      console.log("...");

      let wTokenBalanceBeforeTx2 = await wrapperContract.methods.balanceOf(instance.address).call();
      console.log("WrappedToken balance before tx2: ",wTokenBalanceBeforeTx2);
      let whaleAccountBalanceBeforeTx2 = await USDCContract.methods.balanceOf(whaleAccount).call();
      //payment invoice 2 ref. 0x494e56332d32343002
      await instance.payInvoiceERC20(
        payeeInv2,
        whaleAccount,
        7,
        amountToPayInv2,
        0,
        "0x494e56332d32343002",
        {from: whaleAccount}
      );

      let cUSDCTokenBalanceAfterTx2 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log("cToken balance after tx2 :",cUSDCTokenBalanceAfterTx2);
      let wTokenBalanceAfterTx2 = await wrapperContract.methods.balanceOf(instance.address).call();
      console.log("WrappedToken balance after tx2: ",wTokenBalanceAfterTx2);
      let expectedWhaleAccountBalanceAfterTx2 = web3.utils.toBN(whaleAccountBalanceBeforeTx2).sub(web3.utils.toBN(amountToPayInv2)).toString();
      let whaleAccountBalanceAfterTx2 = await USDCContract.methods.balanceOf(whaleAccount).call();

      assert.equal(whaleAccountBalanceAfterTx2,expectedWhaleAccountBalanceAfterTx2,"Whale account balance doens't match expected balance after tx2");
      assert(wTokenBalanceAfterTx2 > wTokenBalanceBeforeTx2, "wToken balance hasn't changed");

      //increase time and block number to force interest gathering. Without both, Truffle test throws an arithmetic overflow error
      let currentBlockTx2 = await web3.eth.getBlockNumber();
      console.log("...");
      console.log("Increasing time and blocks to gather interest after tx2...");
      await provider.request({method: 'evm_increaseTime', params: [10000000]});
      await time.advanceBlockTo(currentBlockTx2 + 999); //999 + 1 block
      console.log("Increased time with 10000000 seconds, advanced 1000 blocks");
      console.log("...");

      //test redeem
      let cUSDCTokenBalanceBeforeRedeemingFromCompound = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log("cToken balance before redeeming: ",cUSDCTokenBalanceBeforeRedeemingFromCompound);
      let USDCTokenBalanceBeforeRedeemingFromCompound = await USDCContract.methods.balanceOf(instance.address).call();
      console.log("USDC balance before redeeming: ",USDCTokenBalanceBeforeRedeemingFromCompound);

      //create array with payment references to redeem
      let redeemArray = ["0x494e56332d32343001","0x494e56332d32343002"];
      console.log("Added payment references to redeemArray");

      //redeem from Compound and pay all invoices + interest
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
      console.log("Whale balance before payout: ",whaleAccountBalanceAfterTx2);
      console.log("Whale balance after interest payout: ",whaleAccountBalanceAfterInterestPayout);
      
      assert(whaleAccountBalanceAfterInterestPayout > whaleAccountBalanceAfterTx2,"Wrong whale balance after interest payout");
      let expectedPayeeUSDCBalanceAfterPayout = (web3.utils.toBN(payeeUSDCBalanceInitial).add(web3.utils.toBN(amountToPayInv1)).add(web3.utils.toBN(amountToPayInv2))).toString();
      console.log("Expected payee balance ([accounts6]) after payout: ",expectedPayeeUSDCBalanceAfterPayout);
      assert.equal(expectedPayeeUSDCBalanceAfterPayout, payeeUSDCBalance,"Payee USDC balance mismatch");

   });
  });

});