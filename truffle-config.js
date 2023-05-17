module.exports = {
  compilers: {
    solc: {
      version: "^0.8.19", 
    }
  },
  networks: {
    develop: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // match any network
      websockets: true,
    },  
  },
  dashboard: {
    port: 24012,  
  }
}