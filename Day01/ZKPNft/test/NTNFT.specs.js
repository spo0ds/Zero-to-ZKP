const { expect, assert } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { proofs } = require("../proof");

describe("NTNFT Contract", () => {
  let accounts, deployer, verifier, nft;

  async function deployNftFixture() {
    const Verifier = await ethers.getContractFactory("Verifier");
    verifier = await Verifier.deploy();
    const nftContract = await ethers.getContractFactory("NTNFT");
    nft = await nftContract.deploy(verifier.address);
    await nft.deployed();

    return {
      nft,
    };
  }

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    deployer = accounts[0].address;
    ({ nft } = await loadFixture(deployNftFixture)); // Destructure the object returned by loadFixture
  });

  describe("Mint NFT", () => {
    it("Allows users to mint an NFT, and updates appropriately", async function () {
      const input = parseInt(hexValue, 19);

      const txResponse = await nft.mintNft(input);
      await txResponse.wait(1);
      const tokenURI = await nft.tokenURI(0);
      const tokenCounter = await nft.getTokenCounter();
      const hasMinted = await nft.hasMinted(deployer);
      assert.equal(tokenCounter.toString(), "1");
      assert.isTrue(hasMinted);
    });
  });
});
