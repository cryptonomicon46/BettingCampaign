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
const { Console } = require("console");

const [motoGp_date, moto2_date, wsbk_date, stopDate, notYetStopped] = [
  new Date("2/12/2023"),
  new Date("2/12/2023"),
  new Date("2/12/2023"),
  new Date("2/8/2023"), //Wednesday
  new Date("2/7/2023"), //Tuesday
];

const [motoGP_ID, moto2_ID, wsbk_ID] = [1, 2, 3];
const [AcceptingBets, Closed, RevealWinner] = [1, 2, 3];

describe("BettingCampaign: Basic tests", function () {
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
  it("Only owner can update the entry fee", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign.connect(owner).updateEntryFee(parseEther("0.5"))
    )
      .to.emit(bettingCampaign, "EntryFeeUpdated")
      .withArgs(parseEther("0.5"));

    await expect(
      bettingCampaign.connect(addr1).updateEntryFee(parseEther("0.5"))
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });
});

describe("BettingCampaign: Launch campaigns", function () {
  async function deployFixture() {
    [owner, addr1, addr2] = await ethers.getSigners();
    const BettingCampaign = await ethers.getContractFactory("BettingCampaign");
    const bettingCampaign = await BettingCampaign.deploy();
    await bettingCampaign.deployed();

    return { owner, addr1, addr2, bettingCampaign };
  }

  it("Launch MotoGp Campaign: Create a campaign and get back campaign Info", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    const [raceNum, raceDate, raceStage, raceLeague] =
      await bettingCampaign.getCampaignInfo(1);

    expect(raceNum).to.be.equal(BigNumber.from("1"));
    expect(raceDate).to.be.equal(Date.parse(motoGp_date));
    expect(raceStage).to.be.equal(BigNumber.from(AcceptingBets));
    expect(raceLeague).to.be.equal(BigNumber.from(motoGP_ID));
  });

  it("Launch Moto2 Campaign: Create a Moto2 campaign and get back campaign Info", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);
    //Create MotoGP Campaign =1
    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    //Create Moto2 campaign =2
    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(moto2_ID, 1, Date.parse(moto2_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(moto2_ID, 1, Date.parse(moto2_date));
    const [raceNum, raceDate, raceStage, raceLeague] =
      await bettingCampaign.getCampaignInfo(2);
    // console.log(await bettingCampaign.getCampaignInfo(2));

    expect(raceNum).to.be.equal(BigNumber.from("1"));
    expect(raceDate).to.be.equal(Date.parse(moto2_date));
    expect(raceStage).to.be.equal(BigNumber.from(AcceptingBets));
    expect(raceLeague).to.be.equal(BigNumber.from(moto2_ID));
  });

  it("Launch WSBK Campaign: Create a campaign and get back campaign Info", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    //Create MotoGP Campaign =1
    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    //Create Moto2 campaign =2
    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(moto2_ID, 1, Date.parse(moto2_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(moto2_ID, 1, Date.parse(moto2_date));

    //Create WSBK campaign
    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(wsbk_ID, 1, Date.parse(wsbk_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(wsbk_ID, 1, Date.parse(wsbk_date));

    const [raceNum, raceDate, raceStage, raceLeague] =
      await bettingCampaign.getCampaignInfo(3);

    expect(raceNum).to.be.equal(BigNumber.from("1"));
    expect(raceDate).to.be.equal(Date.parse(wsbk_date));
    expect(raceStage).to.be.equal(BigNumber.from(AcceptingBets));
    expect(raceLeague).to.be.equal(BigNumber.from(wsbk_ID));
  });

  it("Launch MotoGp Campaign and change stage: Only owner can change the stage of the campaign ", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    await expect(
      bettingCampaign
        .connect(addr1)
        .changeCampaignStage(motoGP_ID, RevealWinner)
    ).to.be.revertedWith("Ownable: caller is not the owner");

    await expect(
      bettingCampaign
        .connect(owner)
        .changeCampaignStage(motoGP_ID, RevealWinner)
    )
      .to.be.emit(bettingCampaign, "CampaignStageChanged")
      .withArgs(motoGP_ID, RevealWinner);

    await expect(
      bettingCampaign.connect(owner).changeCampaignStage(motoGP_ID, Closed)
    )
      .to.be.emit(bettingCampaign, "CampaignStageChanged")
      .withArgs(motoGP_ID, Closed);

    await expect(
      bettingCampaign
        .connect(owner)
        .changeCampaignStage(motoGP_ID, AcceptingBets)
    )
      .to.be.emit(bettingCampaign, "CampaignStageChanged")
      .withArgs(motoGP_ID, AcceptingBets);
  });
});

describe("BettingCampaign: Accept bets", function () {
  async function deployFixture() {
    [owner, addr1, addr2] = await ethers.getSigners();
    const BettingCampaign = await ethers.getContractFactory("BettingCampaign");
    const bettingCampaign = await BettingCampaign.deploy();
    await bettingCampaign.deployed();

    return { owner, addr1, addr2, bettingCampaign };
  }

  it("Do not Accept bets#1: Launch MotoGp Campaign but do not meet the entry criteria", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    await expect(
      bettingCampaign.AcceptBets(motoGP_ID, { value: parseEther("0.5") })
    ).to.be.revertedWith(
      "BettingCampaign: Entry fee criteria criteria not met!"
    );

    await expect(
      bettingCampaign.AcceptBets(10, { value: parseEther("1") })
    ).to.be.revertedWith("BettingCampaign: Invalid campaign ID number");

    await expect(
      bettingCampaign.AcceptBets(0, { value: parseEther("1") })
    ).to.be.revertedWith("BettingCampaign: Invalid campaign ID number");
  });

  it("Do not Accept bets#2: Launch MotoGp Campaign all the requirements to accept a bet", async function () {
    const { owner, addr1, bettingCampaign } = await loadFixture(deployFixture);

    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    Console.log("Uncomment or run timebased tests separately");
    // await expect(
    //   bettingCampaign.AcceptBets(motoGP_ID, { value: parseEther("1") })
    // )
    //   .to.emit(bettingCampaign, "AcceptedBet")
    //   .withArgs(motoGP_ID, owner.address);

    // await time.increase(Date.parse(stopDate));
    // await expect(
    //   bettingCampaign.AcceptBets(motoGP_ID, { value: parseEther("1") })
    // ).to.be.revertedWith(
    //   "BettingCampaign: Currently not accepting bets for this campaign!"
    // );
  });

  it("Accept Bets: Check the owner balance and campaign balance", async function () {
    const { owner, addr1, addr2, bettingCampaign } = await loadFixture(
      deployFixture
    );

    await expect(
      bettingCampaign
        .connect(owner)
        .createCampaign(motoGP_ID, 1, Date.parse(motoGp_date))
    )
      .to.emit(bettingCampaign, "CampaignCreated")
      .withArgs(motoGP_ID, 1, Date.parse(motoGp_date));

    await expect(
      bettingCampaign
        .connect(addr1)
        .AcceptBets(motoGP_ID, { value: parseEther("1") })
    )
      .to.emit(bettingCampaign, "AcceptedBet")
      .withArgs(motoGP_ID, addr1.address);

    expect(await bettingCampaign.campaginBalance(motoGP_ID)).to.equal(
      parseEther("1.0")
    );
    expect(await bettingCampaign.userBalance(addr1.address)).to.equal(
      parseEther("1.0")
    );

    await expect(
      bettingCampaign
        .connect(addr2)
        .AcceptBets(motoGP_ID, { value: parseEther("1") })
    )
      .to.emit(bettingCampaign, "AcceptedBet")
      .withArgs(motoGP_ID, addr2.address);

    expect(await bettingCampaign.campaginBalance(motoGP_ID)).to.equal(
      parseEther("2.0")
    );
    expect(await bettingCampaign.userBalance(addr1.address)).to.equal(
      parseEther("1.0")
    );
  });
});
