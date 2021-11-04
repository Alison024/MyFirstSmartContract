
let HDWalletProvider = require("truffle-hdwallet-provider");
const dotenv = require('dotenv');
dotenv.config();
module.exports = {
  networks: {
     development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
     },
    rinkeby: {
      provider: ()=>{
        return new HDWalletProvider([process.env.PRIVATE_KEY],
          `https://rinkeby.infura.io/v3/${process.env.PROJ_ID}`);
      },
      network_id: 4, 
      gas: 4000000,
      gasPrice: 21000000000
    }
    
  },
  api_keys: {
    etherscan: process.env.ETHERSCAN_KEY,
  },
  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
       version: "0.8.6",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  },
  plugins: ["solidity-coverage","truffle-plugin-verify"]

  /*db: {
    enabled: false
  }*/
};
