require("@nomicfoundation/hardhat-toolbox");

require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("solidity-coverage");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const GOERLI_URL_ALCHEMY = process.env.GOERLI_URL_ALCHEMY;
const GOERLI_ALCHEMY_KEY = process.env.GOERLI_ALCHEMY_KEY;
const MAINNET_URL_ALCHEMY = process.env.MAINNET_URL_ALCHEMY;
const MAINNET_ALCHEMY_KEY = process.env.MAINNET_ALCHEMY_KEY;
const ETH_API_KEY = process.env.ETH_API_KEY;
const MAINNET_FORK_URL = process.env.MAINNET_FORK_URL;

// require('hardhat-ethernal');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

task(
  "blockNumber",
  "Prints the current block number",
  async (_, { ethers }) => {
    await ethers.provider.getBlockNumber().then((blockNumber) => {
      console.log("Current block number: " + blockNumber);
    });
  }
);
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.7.6",
  settings: {
    evmVersion: "istanbul",
    optimizer: {
      enabled: true,
      runs: 1000,
    },
  },
  viaIR: true,
  defaultNetwork: "hardhat",
  paths: {
    artifacts: "./src/artifacts",
  },
  networks: {
    hardhat: {
      forking: {
        url: `${MAINNET_FORK_URL}`,
        accounts: [`0x${PRIVATE_KEY}`],
      },
    },
    goerli: {
      url: `${GOERLI_URL_ALCHEMY}${GOERLI_ALCHEMY_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    mainnet: {
      url: `${MAINNET_URL_ALCHEMY}${MAINNET_ALCHEMY_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },

  etherscan: {
    apiKey: {
      goerli: ETH_API_KEY,
      mainnet: ETH_API_KEY,
    },
  },
};
