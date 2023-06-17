const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("Deploying NFT...");

  const verifier = await ethers.getContract("Verifier", deployer);

  log("------------------------");
  const args = [verifier.address]; // BasicNFT doesn't take any constructor parameters
  const basicNft = await deploy("NTNFT", {
    from: deployer,
    args: args,
    logs: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  console.log("Deployed NFT!");
  console.log(`NFT deployed at ${basicNft.address}`);

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log("Verifying...");
    await verify(basicNft.address, args);
  }

  log("--------------------------");
};
