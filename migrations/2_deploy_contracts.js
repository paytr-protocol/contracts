const Paytr = artifacts.require("Paytr.sol");

module.exports = function (deployer) {
  deployer.deploy(Paytr, "0x83C766237dD04EB47F62784218839F892A691E84","0xc3d688B66703497DAA19211EEdff47f25384cdc3",6,"0x399F5EE127ce7432E4921a61b8CF52b0af52cbfE");
};