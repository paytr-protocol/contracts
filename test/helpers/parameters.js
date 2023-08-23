const {CometAbi, Erc20Abi, wrapperContractABI} = require('./abi');
const { time } = require("@openzeppelin/test-helpers");

const CometContract = new web3.eth.Contract(CometAbi, "0xc3d688B66703497DAA19211EEdff47f25384cdc3");
const wrapperContract = new web3.eth.Contract(wrapperContractABI, "0xFd55fCd10d7De6C6205dBBa45C4aA67d547AD8F2");
const USDCContract = new web3.eth.Contract(Erc20Abi, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
const cTokenContract = new web3.eth.Contract(Erc20Abi, "0xc3d688B66703497DAA19211EEdff47f25384cdc3");
const whaleAccount = "0x7713974908Be4BEd47172370115e8b1219F4A5f0";
const compTokenContract = new web3.eth.Contract(Erc20Abi, "0xc00e94Cb662C3520282E6f5717214004A7f26888");
const provider = config.provider;

module.exports = {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, compTokenContract, provider};