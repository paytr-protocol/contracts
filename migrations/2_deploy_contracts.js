const Paytr = artifacts.require("Paytr.sol");

module.exports = function (deployer) {
  deployer.deploy(Paytr, "0x83C766237dD04EB47F62784218839F892A691E84","0x3EE77595A8459e93C2888b13aDB354017B198188",6,"0x131eb294E3803F23dc2882AB795631A12D1d8929");
};