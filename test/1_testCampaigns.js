const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { parseEther, formatEther } = require("ethers/lib/utils");
const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { parse } = require("dotenv");
const { ADDRESS_ZERO } = require("@uniswap/v3-sdk");
const {
  isCallTrace,
} = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

const motoGp_date = new Date("1/2/2023");
const moto2_date = new Date("1/10/2023");
const wsbk_date = new Date("1/18/2023");

describe("BettingCampaign", function () {
  async function deployFixture() {
    [owner, addr1, addr2] = await ethers.getSigners();
    const BettingCampaign = await ethers.getContractFactory("BettingCampaign");
    const bettingCampaign = await BettingCampaign.deploy();
    await bettingCampaign.deployed();

    return { owner, addr1, addr2, bettingCampaign };
  }

  it("Check contract is a proper address", async function () {
    const { bettingCampaign } = await loadFixture(deployFixture);
    expect(bettingCampaign.address).to.be.a.properAddress;
  });
  it("Check deployer is the owner of the conract ", async function () {
    const { owner, bettingCampaign } = await loadFixture(deployFixture);

    expect(await bettingCampaign.owner()).to.equal(owner.address);
  });
  it("Check if deployer can transfer ownership address", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    expect(await bettingCampaign.owner()).to.equal(owner.address);

    await expect(
      bettingCampaign.connect(owner).transferOwnership(addr1.address)
    )
      .to.emit(bettingCampaign, "OwnershipTransferred")
      .withArgs(owner.address, addr1.address);
  });
  it("Ensure that addresses other than the owner cannot launch a campaign", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign
        .connect(addr1)
        .createCampaign(1, 1, Date.parse(motoGp_date))
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
  it("Check if deployer can launch a campaign", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(1, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(1, 1, Date.parse(motoGp_date));
  });
});
