var assert = require('assert');
const truffleAssert = require('truffle-assertions');

const Paytr = artifacts.require("Paytr");

contract("Paytr", (accounts) => {  

    let instance;
    beforeEach('should setup the contract instances', async () => {
      instance = await Paytr.deployed();
    });
    
    describe("Updating parameters", () => {
      it("should be able for the contract owner to update the contract parameters with correct values", async () => {
        let setParams = await instance.setContractParameters(
            20, //fee%
            7, //minDueDate
            300, //maxDueDate
            3, //minAmount
            100000000, //maxAmount,
            5 //max payout array size
        )
        truffleAssert.eventEmitted(setParams, 'ContractParametersUpdatedEvent');
      });

      it("should be able for the contract owner to set a maxAmount of $5m (5000000000000 or 5**12)", async () => {
        let setParams = await instance.setContractParameters(
            20,
            7,
            300,
            3, //minAmount 0
            5**12,
            5
        )
        truffleAssert.eventEmitted(setParams, 'ContractParametersUpdatedEvent');
      });

      it("random address shouldn't be able to update the contract parameters", async () => {
        await truffleAssert.fails(instance.setContractParameters(
            20,
            7,
            300,
            3,
            100000000,
            5,
            {from: accounts[2]}
        ),
        truffleAssert.ErrorType.REVERT);
      });

      it("should throw an error when setting the fee% higher than 50", async () => {
        await truffleAssert.fails(instance.setContractParameters(
            51, //51% fee
            7,
            300,
            3,
            100000000,
            5
        ),
        truffleAssert.ErrorType.REVERT)
      });

      it("should throw an error when setting the minDueData lower than 5", async () => {
        await truffleAssert.fails(instance.setContractParameters(
            20,
            1,
            300,
            3,
            100000000,
            5
        ),
        truffleAssert.ErrorType.REVERT)
      });

      it("should throw an error when setting the maxDueData higher than 365", async () => {
        await truffleAssert.fails(instance.setContractParameters(
            20,
            7,
            730, //2 years
            3,
            100000000,
            5
        ),
        truffleAssert.ErrorType.REVERT)
      });

      it("should throw an error when setting the minAmount lower than 1 (to 0)", async () => {
        await truffleAssert.fails(instance.setContractParameters(
            20,
            7,
            300,
            0, //minAmount 0
            100000000,
            5
        ),
        truffleAssert.ErrorType.REVERT)
      });

      it("should throw an error when setting the maxPayoutArraySize lower than 1 (to 0)", async () => {
        await truffleAssert.fails(instance.setContractParameters(
            20,
            7,
            300,
            0,
            100000000,
            0 //maxPayoutArraySize 0
        ),
        truffleAssert.ErrorType.REVERT)
      });

    });
})