module.exports = {
  compilers: {
    solc: {
      version: "0.8.19",
    }
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // match any network
    },  
  },
  dashboard: {
    port: 24012,  
  }
}