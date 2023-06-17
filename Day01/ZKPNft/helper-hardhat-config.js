const { ethers } = require("hardhat");

const networkConfig = {
  5: {
    name: "goerli",
    callBackGasLimit: "500000",
  },
  31337: {
    name: "hardhat",
    callBackGasLimit: "500000",
  },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
  networkConfig,
  developmentChains,
};
