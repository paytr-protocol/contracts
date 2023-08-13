const Paytr = artifacts.require("Paytr.sol");

module.exports = function (deployer) {
  deployer.deploy(Paytr, "0xc3d688B66703497DAA19211EEdff47f25384cdc3","0xFd55fCd10d7De6C6205dBBa45C4aA67d547AD8F2","0x399F5EE127ce7432E4921a61b8CF52b0af52cbfE",10, 7, 30, 10, 100000000000, 5);//100,000 USDC
};