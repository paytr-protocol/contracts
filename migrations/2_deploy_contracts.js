const Paytr = artifacts.require("Paytr.sol");

let minDueDateParameter = 7 * 86400;
let maxDueDateParameter = 365 * 86400;
let minAmountParameter = 10 * 10**6;
let maxAmountParameter = 100_000 * 10**6;
let maxPayOutArraySize = 30;
let cometAddress = "0xF09F0369aB0a875254fB565E52226c88f10Bc839";
let wrapperAddress = "0x797D7126C35E0894Ba76043dA874095db4776035";

module.exports = function (deployer) {
  deployer.deploy(Paytr, cometAddress, wrapperAddress, 9000, minDueDateParameter, maxDueDateParameter, minAmountParameter, maxAmountParameter, maxPayOutArraySize);
};