require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

const infuraApi = process.env.INFURA_API;

module.exports = {
  compilers: {
    solc: {
      version: "^0.8.19", 
    }
  },
  networks: {
    myFork: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "5", // match any network
      websockets: true
    },  
  },
  dashboard: {
    port: 24012,  
  },
  
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  }
}