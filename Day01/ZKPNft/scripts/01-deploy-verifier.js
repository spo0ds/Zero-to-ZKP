const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("Deploying NFT...");

  log("------------------------");
  const args = []; // BasicNFT doesn't take any constructor parameters
  const verifier = await deploy("Verifier", {
    from: deployer,
    args: args,
    logs: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  console.log("Deployed Verifier!");
  console.log(`NFT deployed at ${verifier.address}`);

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log("Verifying...");
    await verify(verifier.address, args);
  }

  log("--------------------------");
};
