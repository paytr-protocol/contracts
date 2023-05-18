var assert = require('assert');
const truffleAssert = require('truffle-assertions');

const Paytr = artifacts.require("Paytr");
const CometAbi = [{"inputs":[{"internalType":"address","name":"_logic","type":"address"},{"internalType":"address","name":"admin_","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"}],"stateMutability":"payable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"admin_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"implementation_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]

const Erc20Abi = [{ "constant": true, "inputs": [], "name": "name", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_spender", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "approve", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "totalSupply", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_from", "type": "address" }, { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transferFrom", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "decimals", "outputs": [ { "name": "", "type": "uint8" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" } ], "name": "balanceOf", "outputs": [ { "name": "balance", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "symbol", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transfer", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" }, { "name": "_spender", "type": "address" } ], "name": "allowance", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "payable": true, "stateMutability": "payable", "type": "fallback" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "owner", "type": "address" }, { "indexed": true, "name": "spender", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "from", "type": "address" }, { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Transfer", "type": "event" }]

const CometContract = new web3.eth.Contract(CometAbi, "0xc3d688B66703497DAA19211EEdff47f25384cdc3");
const USDCContract = new web3.eth.Contract(Erc20Abi, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
const cTokenContract = new web3.eth.Contract(Erc20Abi, "0xc3d688B66703497DAA19211EEdff47f25384cdc3");
const WETHContract = new web3.eth.Contract(Erc20Abi, "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
const whaleAccount = "0x7713974908Be4BEd47172370115e8b1219F4A5f0";

let amountToPay = 1500000000;
let feeAmount = 100000;

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });
  
  describe("Small checks and standalone payments", () => {
    it("should be able to add a Comet address as contract owner", async () => {
        await instance.addCometAddress("0xc3d688B66703497DAA19211EEdff47f25384cdc3", 6, {from: accounts[0]});
    });

    it("should be able to add an ERC20FeeProxyAddress as contract owner", async () => {
        await instance.addRequestNetworkFeeAddress(
          "0xb794f5ea0ba39494ce839613fffba74279579268",//random address
          {from: accounts[0]}
        ); 
    });

    it("shouldn't be able to add an ERC20FeeProxyAddress as non-contract owner", async () => {
      await truffleAssert.reverts(instance.addRequestNetworkFeeAddress(
        "0xb794f5ea0ba39494ce839613fffba74279579268",//random address
        {from: accounts[9]}
      )); 
    });

    it("the contract should be deployed with an active Comet address (0xc3d688B66703497DAA19211EEdff47f25384cdc3) in the mapping, ", async () => {
      let result = await instance.allowedCometInfo("0xc3d688B66703497DAA19211EEdff47f25384cdc3");
      assert.equal(result[1].length,1,"No Comet contract in constructor!");

    });

    it("should be able to make an ERC20 payment using USDC", async () => {

      let payerBalanceBefore = await USDCContract.methods.balanceOf(whaleAccount).call();
      let instanceCtokenBalanceBefore = await cTokenContract.methods.balanceOf(instance.address).call();

      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});

      await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x494e56332d32343034",
        CometContract._address,
        {from: whaleAccount}
      );
      
      let payerBalanceAfter = await USDCContract.methods.balanceOf(whaleAccount).call();
      let instanceCtokenBalanceAfter = await cTokenContract.methods.balanceOf(instance.address).call();

      assert(payerBalanceBefore > payerBalanceAfter, "USDC balance before the tx == balance after the tx ");
      assert(instanceCtokenBalanceAfter > instanceCtokenBalanceBefore, "cToken balance hasn't changed");
    });

    it("should be able to make an ERC20 payment using USDC and include a fee", async () => {

      let payerBalanceBefore = await USDCContract.methods.balanceOf(whaleAccount).call();
      let instanceCtokenBalanceBefore = await cTokenContract.methods.balanceOf(instance.address).call();

      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});

      await instance.payInvoiceERC20WithFee(
        USDCContract._address,
        accounts[6],
        accounts[3],
        30,
        amountToPay,
        feeAmount,
        "0x4943546332d32343999",
        CometContract._address,
        {from: whaleAccount}
      );
      
      let payerBalanceAfter = await USDCContract.methods.balanceOf(whaleAccount).call();
      let instanceCtokenBalanceAfter = await cTokenContract.methods.balanceOf(instance.address).call();

      assert(payerBalanceBefore > payerBalanceAfter, "USDC balance hasn't changed");
      assert(instanceCtokenBalanceAfter > instanceCtokenBalanceBefore, "cToken balance hasn't changed");
    });

    it("should be able to make an ERC20 payment using USDC while using value 0 as due date", async () => {

      let myTokenBalanceBefore = await USDCContract.methods.balanceOf(whaleAccount).call();
      let instanceCtokenBalanceBefore = await cTokenContract.methods.balanceOf(instance.address).call();

      await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        0,
        amountToPay,
        "0x494e56332d32343035",
        CometContract._address,
        {from: whaleAccount}
      );
      
      let myTokenBalanceAfter = await USDCContract.methods.balanceOf(whaleAccount).call();
      let instanceCtokenBalanceAfter = await cTokenContract.methods.balanceOf(instance.address).call();

      assert.notEqual(myTokenBalanceBefore,myTokenBalanceAfter, "USDC balance is equal!");
      assert.notEqual(instanceCtokenBalanceBefore,instanceCtokenBalanceAfter, "cToken balance is equal!");
    });

    it("should revert when someone tries to use the '0 address' as payee address", async () => {
      await truffleAssert.reverts(instance.payInvoiceERC20(
        USDCContract._address,
        "0x0000000000000000000000000000000000000000",
        30,
        amountToPay,
        "0x494e56332d32343036",
        CometContract._address,
        {from: whaleAccount}
      ));
    });

    it("should revert when someone tries to input a value of 0 as amount to pay", async () => {
      let amountToPay = 0;
      await truffleAssert.reverts(instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x494e56332d32343034",
        CometContract._address,
        {from: whaleAccount}
      ));
    });

    it("should revert when someone tries to use a token != the base asset (USDC)", async () => {
      let amountToPay = 0;
      await truffleAssert.reverts(instance.payInvoiceERC20(
        WETHContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x494e56332d32343034",
        CometContract._address,
        {from: whaleAccount}
      ));
    });

    it("should revert when someone tries to use a non-whitelisted Comet address", async () => {
      let amountToPay = 0;
      await truffleAssert.reverts(instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x494e56332d32343034",
        "0x9A539EEc489AAA03D588212a164d0abdB5F08F5F",
        {from: whaleAccount}
      ));
    });

    it("should allow the payer to update the due date of a payment reference", async () => {
      let currentTime = Math.floor(Date.now() / 1000);
      let newDueDate = currentTime + 604800 //1 week in seconds;
      await instance.updateDueDate(
        "0x494e56332d32343035",
        newDueDate,
        {from: whaleAccount}
      );
    });

    it("should revert if the payer wants to update the due date of a payment reference when the due date is smaller than current time + 1 day", async () => {
      let currentTime = Math.floor(Date.now() / 1000);
      let newDueDate = currentTime + 500;
      await truffleAssert.reverts(instance.updateDueDate(
        "0x494e56332d32343035",
        newDueDate,
        {from: whaleAccount}
      ));
    });

    it("should revert if the payer wants to update the due date of a payment reference with a 0 due date", async () => {
      let newDueDate = 0;
      await truffleAssert.reverts(instance.updateDueDate(
        "0x494e56332d32343035",
        newDueDate,
        {from: whaleAccount}
      ));
    });

    it("should revert if the payer wants to update the due date of a payment where the due date is > 0", async () => {
      let currentTime = Math.floor(Date.now() / 1000);
      let newDueDate = currentTime + + 604800; //1 week in seconds;
      await truffleAssert.reverts(instance.updateDueDate(
        "0x494e56332d32343035",
        newDueDate,
        {from: whaleAccount}
      ));
    });

    it("should revert when a third party wants to update the due date of a payment reference", async () => {
      let currentTime = Math.floor(Date.now() / 1000);
      let newDueDate = currentTime + 604800; //1 week in seconds
      await truffleAssert.reverts(instance.updateDueDate(
        "0x494e56332d32343035",
        newDueDate,
        {from: accounts[2]}
      ));
    });
  });

  describe("Test same payment reference", () => {
    it("should be able to use the same payment reference twice, for different payees", async () => {
      //send funds to accounts[4]
      let accounts4BalanceBefore = await USDCContract.methods.balanceOf(accounts[4]).call();
      await USDCContract.methods.transfer(accounts[4], 500000000000).send({from: whaleAccount});
      let accounts4BalanceAfter = await USDCContract.methods.balanceOf(accounts[4]).call();
      assert(accounts4BalanceBefore < accounts4BalanceAfter);
      //Approval
      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});
      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: accounts[4]});

      //USDC payment first payer

      await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x194e56332d32347777",
        CometContract._address,
        {from: whaleAccount}
      );

      //USDC payment second payer

      await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[7],
        30,
        amountToPay,
        "0x194e56332d32347777",
        CometContract._address,
        {from: accounts[4]}
      );

      //USDC payment first payer with fee

      await instance.payInvoiceERC20WithFee(
        USDCContract._address,
        accounts[6],
        accounts[9],
        30,
        amountToPay,
        feeAmount,
        "0x194e56332d323400001",
        CometContract._address,
        {from: whaleAccount}
      );
      
      //USDC payment second payer with fee

      await instance.payInvoiceERC20WithFee(
        USDCContract._address,
        accounts[2],
        accounts[9],
        30,
        amountToPay,
        feeAmount,
        "0x194e56332d323400001",
        CometContract._address,
        {from: accounts[4]}
      );

    })//end it(...)
    it("should revert when trying to use the same payment reference twice for the same payee", async () => {
      
      await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x23e56332d3131516",
        CometContract._address,
        {from: whaleAccount}
      );

      await truffleAssert.reverts(instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x23e56332d3131516",
        CometContract._address,
        {from: whaleAccount}
      ));



    })//end it(...)
  })//end describe



});