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
  }
}