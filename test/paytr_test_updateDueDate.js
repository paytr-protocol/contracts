var assert = require('assert');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const Paytr = artifacts.require("Paytr");
const { USDCContract, whaleAccount, provider } = require('./helpers/parameters');

contract("Paytr", (accounts) => {  
    const payee = accounts[6];
    let amountToPay = 1000*10**6; //1000 USDC
    

    let instance;
    beforeEach('should setup the contract instances', async () => {
      instance = await Paytr.deployed();
      await USDCContract.methods.approve(instance.address, amountToPay).send({from: whaleAccount});
    });
    
    describe("Update the due date of a payment reference", () => {
      it("the payer of a payment reference should be able to update the due date when the original due date is 0", async () => {
        let currentTime = await time.latest();
        let numberOfDaysToAdd = web3.utils.toBN(7);
        let newdueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();
     
        let payment = await instance.payInvoiceERC20(
          payee,
          whaleAccount, //dummy feeAddress
          0, //0 dueDate
          amountToPay,
          0, //no fee requires 0 as parameter input        
          "0x494e56332d32343034",
          {from: whaleAccount}
        );
        
        truffleAssert.eventEmitted(payment, "PaymentERC20Event");

        //update dueDate of payment reference 0x494e56332d32343034;
        let update = await instance.updateDueDate("0x494e56332d32343034", newdueDate, {from: whaleAccount});

        truffleAssert.eventEmitted(update, "DueDateUpdatedEvent");
    
      });

      it("shouldn't be possible to update the due date of a payment reference, when it already has a due date != 0", async () => {
        let currentTime = await time.latest();
        let numberOfDaysToAdd = web3.utils.toBN(7);
        let newdueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

        await truffleAssert.fails(instance.updateDueDate("0x494e56332d32343034", newdueDate, {from: whaleAccount}), truffleAssert.ErrorType.REVERT);
        
      });

      it("should revert when an account != the payee tries to update the due date of a payment", async () => {
        let currentTime = await time.latest();
        let numberOfDaysToAdd = web3.utils.toBN(7);
        let newdueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

        await truffleAssert.fails(instance.updateDueDate("0x494e56332d32343034", newdueDate, {from: accounts[3]}), truffleAssert.ErrorType.REVERT);
        
      });

      it("should revert when trying to update a payment reference that is unknown to the contract", async () => {
        let currentTime = await time.latest();
        let numberOfDaysToAdd = web3.utils.toBN(7);
        let newdueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

        await truffleAssert.fails(instance.updateDueDate("0x494e56332d32000000", newdueDate, {from: whaleAccount}), truffleAssert.ErrorType.REVERT);
        
      });

      it("should revert when trying to update a payment reference with a value > the allowed due date (because of contract parameters)", async () => {
        let currentTime = await time.latest();
        let numberOfDaysToAdd = web3.utils.toBN(366); //parameter maxDueDateInDays is set to 365
        let newdueDate = web3.utils.toBN(currentTime).add((numberOfDaysToAdd).mul(web3.utils.toBN(86400))).toString();

        await instance.payInvoiceERC20(
          payee,
          whaleAccount, //dummy feeAddress
          0, //0 dueDate
          amountToPay,
          0, //no fee requires 0 as parameter input        
          "0x494e56332d32343099",
          {from: whaleAccount}
        );

        await truffleAssert.fails(instance.updateDueDate("0x494e56332d32343099", newdueDate, {from: whaleAccount}), truffleAssert.ErrorType.REVERT);

      });

      it("should revert when trying to update a payment reference with a value < the allowed due date", async () => {
        let currentTime = await time.latest();
        let newdueDate = web3.utils.toBN(currentTime).toString();

        await instance.payInvoiceERC20(
          payee,
          whaleAccount, //dummy feeAddress
          0, //0 dueDate
          amountToPay,
          0, //no fee requires 0 as parameter input        
          "0x494e56332d32343999",
          {from: whaleAccount}
        );

        await truffleAssert.fails(instance.updateDueDate("0x494e56332d32343999", newdueDate, {from: whaleAccount}), truffleAssert.ErrorType.REVERT);

      });

    });//end describe

});