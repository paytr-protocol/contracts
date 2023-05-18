
var assert = require('assert');
const truffleAssert = require('truffle-assertions');

const Paytr = artifacts.require("Paytr");
const CometAbi = [{"inputs":[{"internalType":"address","name":"_logic","type":"address"},{"internalType":"address","name":"admin_","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"}],"stateMutability":"payable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"admin_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"implementation_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]

const Erc20Abi = [{ "constant": true, "inputs": [], "name": "name", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_spender", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "approve", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "totalSupply", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_from", "type": "address" }, { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transferFrom", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "decimals", "outputs": [ { "name": "", "type": "uint8" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" } ], "name": "balanceOf", "outputs": [ { "name": "balance", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "symbol", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transfer", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" }, { "name": "_spender", "type": "address" } ], "name": "allowance", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "payable": true, "stateMutability": "payable", "type": "fallback" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "owner", "type": "address" }, { "indexed": true, "name": "spender", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "from", "type": "address" }, { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Transfer", "type": "event" }]

const CometContract = new web3.eth.Contract(CometAbi, "0xc3d688B66703497DAA19211EEdff47f25384cdc3");
const USDCContract = new web3.eth.Contract(Erc20Abi, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
const cTokenContract = new web3.eth.Contract(Erc20Abi, "0xc3d688B66703497DAA19211EEdff47f25384cdc3");
const whaleAccount = "0x7713974908Be4BEd47172370115e8b1219F4A5f0";

let amountToPay = 1500000000;
let feeAmount = 100000;
let totalPaid = null;
let totalPayments = null;
let totalFees = null;
let totalPaymentsWithFee = null;

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });


describe("Normal payment flow of 2 invoices + payout of due invoices", () => {
    const provider = config.provider;
      
    it("the contract needs to pay out all due invoices", async () => {
  
      await web3.eth.sendTransaction({ from: accounts[0], to: whaleAccount, value: 100});
  
      //check total supply:
      let totalSupplyCToken = await cTokenContract.methods.totalSupply().call();
      console.log("test supply: ",totalSupplyCToken)
      //Approval
      await USDCContract.methods.approve(instance.address, 99990000000000).send({from: whaleAccount});
      let contractBalanceBeforeTx1 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log(contractBalanceBeforeTx1);
  
      //USDC payment
  
      let payment = await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x194e56332d32347777",
        CometContract._address,
        {from: whaleAccount}
      );
      truffleAssert.eventEmitted(payment,'PaymentERC20Event');
      let contractBalanceAfterTx1 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log(contractBalanceAfterTx1);
      totalPaid += amountToPay;
      totalPayments += 1;
      console.log("Total paid: ",totalPaid);
      console.log("Total payments: ",totalPayments);
      //end of USDC payment
  
      //USDC payment with fee
      let contractBalanceBeforeTx2 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log(contractBalanceBeforeTx2);
  
      let paymentWithFee = await instance.payInvoiceERC20WithFee(
        USDCContract._address,
        accounts[6],
        accounts[3],
        30,
        amountToPay,
        feeAmount,
        "0x194e56332d32347778",
        CometContract._address,
        {from: whaleAccount}
      );
      truffleAssert.eventEmitted(paymentWithFee,'PaymentERC20EventWithFee');
      let contractBalanceAfterTx2 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log(contractBalanceAfterTx2);
      totalPaid += amountToPay;
      totalPayments += 1;
      totalFees += feeAmount;
      totalPaymentsWithFee += 1;
      console.log("Total paid: ",totalPaid);
      console.log("Total payments: ",totalPayments);
      console.log("Total payments with fee: ",totalPaymentsWithFee);
      console.log("Total fees: ",totalFees);
  
      //end of USDC payment with fee
      
      //USDC payment with 0 due date
      let contractBalanceBeforeTx3 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log(contractBalanceBeforeTx3);
  
      let paymentZeroDueDate = await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        0,
        amountToPay,
        "0x394e56332d32341111",
        CometContract._address,
        {from: whaleAccount}
      );
      truffleAssert.eventEmitted(paymentZeroDueDate,'PaymentERC20Event');
      truffleAssert.eventNotEmitted(paymentZeroDueDate, 'PaymentERC20EventWithFee');
      let contractBalanceAfterTx3 = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log(contractBalanceAfterTx3);
      totalPaid += amountToPay;
      totalPayments += 1;
      console.log("Total paid: ",totalPaid);
      console.log("Total payments: ",totalPayments);
  
      //update due date of payment ref. 0x394e56332d32341111
      let currentTime = Math.floor(Date.now() / 1000);
      let newDueDate = currentTime + 604800 //1 week in seconds;
      let updateDueDate = await instance.updateDueDate(
        "0x394e56332d32341111",
        newDueDate,
        {from: whaleAccount}
      );
      truffleAssert.eventEmitted(updateDueDate,'DueDateUpdatedEvent');
      //end of update due date
  
      //Mine blocks to earn interest
      let contractBalanceBefore = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log("Contract cToken balance before mining extra blocks: ",contractBalanceBefore);
      //console.log("start", await provider.request({method: 'eth_blockNumber', params: []}));
      await provider.request({method: 'evm_mine', params: [{blocks:10050}]});
      //console.log("end", await provider.request({method: 'eth_blockNumber', params: []}));
      let contractBalanceAfter = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log("Contract cToken balance after mining extra blocks: ",contractBalanceAfter);
      let totalInterest = contractBalanceAfter - contractBalanceBefore;
      console.log("Total interest: ",totalInterest);
      let interestPerPayment = totalInterest / totalPayments;
      console.log("Interest per payment reference: ",interestPerPayment);
      let feeAmountPerPayment = totalFees / totalPaymentsWithFee;
      console.log("feeAmount per payment reference: ",feeAmountPerPayment);
  
      //payout   
  
      let payeeBalanceUsdcBeforePayout = await USDCContract.methods.balanceOf(accounts[6]).call();
      console.log("Payee balance USDC before payout function: ",payeeBalanceUsdcBeforePayout);

      console.log("Total to be redeemed: ",totalPaid+totalFees+totalInterest)
      
      let payout = await instance.payOutERC20Invoice([
        [amountToPay, Math.floor(interestPerPayment),0, whaleAccount, accounts[6], USDCContract._address, CometContract._address, whaleAccount, "0x194e56332d32347777"],
        [amountToPay, Math.floor(interestPerPayment),feeAmountPerPayment, whaleAccount, accounts[6], USDCContract._address, CometContract._address, whaleAccount, "0x194e56332d32347778"],
        [amountToPay, Math.floor(interestPerPayment),0, whaleAccount, accounts[6], USDCContract._address, CometContract._address, whaleAccount, "0x394e56332d32341111"],
      ],
        [[USDCContract._address, CometContract._address, totalPaid+totalFees+totalInterest]]
      );
      let contractBalanceAfterPayout = await cTokenContract.methods.balanceOf(instance.address).call();
      console.log("Contract cToken balance after payout: ",contractBalanceAfterPayout);
  
      let expectedBalanceAfterPayout = web3.utils.toBN(payeeBalanceUsdcBeforePayout).add(web3.utils.toBN(totalPaid)).toString();
      console.log("Expected new total: ",expectedBalanceAfterPayout);
      let payeeBalanceUsdcAfterPayout = await USDCContract.methods.balanceOf(accounts[6]).call();
      console.log("Payee balance USDC after payout function: ",payeeBalanceUsdcAfterPayout);
        
      assert(contractBalanceAfterPayout <= 20);
      assert.equal(expectedBalanceAfterPayout,payeeBalanceUsdcAfterPayout, "Payee balance not correct");
      truffleAssert.eventEmitted(payout,'PayOutERC20Event');
      
      });
    });//end describe
});