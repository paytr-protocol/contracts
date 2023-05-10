var assert = require('assert');
const truffleAssert = require('truffle-assertions');

const Paytr = artifacts.require("Paytr");
const CometAbi = [{"inputs":[{"internalType":"address","name":"_logic","type":"address"},{"internalType":"address","name":"admin_","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"}],"stateMutability":"payable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"admin_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"implementation_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]
//const UsdcAbi = [{"inputs":[{"internalType":"address","name":"implementationContract","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"}]
const Erc20Abi = [{ "constant": true, "inputs": [], "name": "name", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_spender", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "approve", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "totalSupply", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_from", "type": "address" }, { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transferFrom", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "decimals", "outputs": [ { "name": "", "type": "uint8" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" } ], "name": "balanceOf", "outputs": [ { "name": "balance", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "symbol", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transfer", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "_owner", "type": "address" }, { "name": "_spender", "type": "address" } ], "name": "allowance", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "payable": true, "stateMutability": "payable", "type": "fallback" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "owner", "type": "address" }, { "indexed": true, "name": "spender", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "from", "type": "address" }, { "indexed": true, "name": "to", "type": "address" }, { "indexed": false, "name": "value", "type": "uint256" } ], "name": "Transfer", "type": "event" }]
const CometContract = new web3.eth.Contract(CometAbi, "0x3EE77595A8459e93C2888b13aDB354017B198188");
const USDCContract = new web3.eth.Contract(Erc20Abi, "0x07865c6E87B9F70255377e024ace6630C1Eaa37F"); //
const WETHContract = new web3.eth.Contract(Erc20Abi, "0x42a71137C09AE83D8d05974960fd607d40033499");
const cTokenContract = new web3.eth.Contract(Erc20Abi, "0x3EE77595A8459e93C2888b13aDB354017B198188");
const whaleAccount = "0x75C0c372da875a4Fc78E8A37f58618a6D18904e8";

let amountToPay = 1500000;
let feeAmount = 100000;

contract("Paytr", (accounts) => {  

  let instance;
  beforeEach('should setup the contract instances', async () => {
    instance = await Paytr.deployed();
  });
  
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

  it("the contract should be deployed with an active Comet address (0xF09F0369aB0a875254fB565E52226c88f10Bc839) in the mapping, ", async () => {
    let result = await instance.allowedCometInfo("0xF09F0369aB0a875254fB565E52226c88f10Bc839");
    assert.equal(result[1].length,1,"No Comet contract in constructor!");

  });

  it("should be able to make an ERC20 payment using USDC", async () => {

    let myTokenBalanceBefore = await USDCContract.methods.balanceOf(whaleAccount).call();
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
    
    let myTokenBalanceAfter = await USDCContract.methods.balanceOf(whaleAccount).call();
    let instanceCtokenBalanceAfter = await cTokenContract.methods.balanceOf(instance.address).call();

    assert(myTokenBalanceBefore > myTokenBalanceAfter, "USDC balance before the tx == balance after the tx ");
    assert(instanceCtokenBalanceAfter > instanceCtokenBalanceBefore, "cToken balance hasn't changed");
  });

  it("should be able to make an ERC20 payment using USDC and include a fee", async () => {

    let myTokenBalanceBefore = await USDCContract.methods.balanceOf(whaleAccount).call();
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
    
    let myTokenBalanceAfter = await USDCContract.methods.balanceOf(whaleAccount).call();
    let instanceCtokenBalanceAfter = await cTokenContract.methods.balanceOf(instance.address).call();

    assert(myTokenBalanceBefore > myTokenBalanceAfter, "USDC balance hasn't changed");
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
      "0x494e56332d32343035", //new payment reference compared to the first payment in the test, to prevent a revert 'Payment reference already used'
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
describe("Normal payment flow + payout of due invoice", () => {
  let totalPaid;
  let totalFees;
  let totalAmountToRedeem;
    it("the contract needs to pay out all due invoices", async () => {
      //Approval
      await USDCContract.methods.approve(instance.address, 1000000000000).send({from: whaleAccount});

      //USDC payment

      await instance.payInvoiceERC20(
        USDCContract._address,
        accounts[6],
        30,
        amountToPay,
        "0x194e56332d32347777",
        CometContract._address,
        {from: whaleAccount}
      );
      totalPaid += amountToPay;
      //end of USDC payment

      //USDC payment with fee
      await instance.payInvoiceERC20WithFee(
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
      console.log(amountToPay);
      totalPaid += amountToPay;
      console.log("Total paid: ",totalPaid);
      totalFees += feeAmount;
      totalAmountToRedeem = new web3.utils.BN(totalPaid + totalFees).toString();
      console.log("Total to redeem: ",totalAmountToRedeem);
      //end of USDC payment with fee
      
      //USDC payment with 0 due date
      // await instance.payInvoiceERC20(
      //   USDCContract._address,
      //   accounts[6],
      //   0,
      //   amountToPay,
      //   "0x394e56332d32341111",
      //   CometContract._address,
      //   {from: whaleAccount}
      // );

      //update due date of payment ref. 0x494e56332d32343035
      // let currentTime = Math.floor(Date.now() / 1000);
      // let newDueDate = currentTime + 604800 //1 week in seconds;
      // await instance.updateDueDate(
      //   "0x394e56332d32341111",
      //   newDueDate,
      //   {from: whaleAccount}
      // );
      //end of update due date

      //pay 3 payment references
    //   struct totalPerAssetToRedeem {        
    //     address asset;
    //     address cometAddress;
    //     uint256 amount;        
    // }
    await instance.payOutERC20Invoice([
      [amountToPay,0,0, whaleAccount, accounts[6], USDCContract._address, CometContract._address, whaleAccount, "0x194e56332d32347777"],
      [amountToPay,0,feeAmount, whaleAccount, accounts[6], USDCContract._address, CometContract._address, whaleAccount, "0x194e56332d32347778"]
    ],
      [[USDCContract._address, CometContract._address, amountToPay*2+feeAmount]]
    );

    //console.log(config.provider)
    // const provider = web3.setProvider(instance.provider);
    console.log("start", await config.provider.send(
      {
        jsonrpc: "2.0",
        method: "eth_blockNumber",
        params:[]
      }
      ));
    await config.provider.send("evm_mine", [{blocks: 5}] ); // mines 5 blocks
    console.log("end", await config.provider.send("eth_blockNumber"));


    });
  });//end describe
});