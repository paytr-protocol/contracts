const Paytr = artifacts.require("Paytr.sol");

let minDueDateParameter = 7 * 86400;
let maxDueDateParameter = 365 * 86400;
let minAmountParameter = 10;
let maxAmountParameter = 100_000 * 10**6;
let maxPayOutArraySize = 30;

module.exports = function (deployer) {
  deployer.deploy(Paytr, "0xc3d688B66703497DAA19211EEdff47f25384cdc3", "0xFd55fCd10d7De6C6205dBBa45C4aA67d547AD8F2", 9000, minDueDateParameter, maxDueDateParameter, minAmountParameter, maxAmountParameter, maxPayOutArraySize);
};