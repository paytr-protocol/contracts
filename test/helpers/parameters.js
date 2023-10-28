const {CometAbi, Erc20Abi, wrapperContractABI} = require('./abi');

const CometContract = new web3.eth.Contract(CometAbi, "0xF09F0369aB0a875254fB565E52226c88f10Bc839");
const wrapperContract = new web3.eth.Contract(wrapperContractABI, "0x797D7126C35E0894Ba76043dA874095db4776035");
const USDCContract = new web3.eth.Contract(Erc20Abi, "0xDB3cB4f2688daAB3BFf59C24cC42D4B6285828e9");
const cTokenContract = new web3.eth.Contract(Erc20Abi, "0xF09F0369aB0a875254fB565E52226c88f10Bc839");
const whaleAccount = "0xFC078A6812eb56320f879A153A0bd23C34D9B508";
const compTokenContract = new web3.eth.Contract(Erc20Abi, "0xc00e94Cb662C3520282E6f5717214004A7f26888");
const provider = config.provider;

module.exports = {CometContract, wrapperContract, USDCContract, cTokenContract, whaleAccount, compTokenContract, provider};