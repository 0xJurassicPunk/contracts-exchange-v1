import { assert, expect } from "chai";
import { BigNumber, Contract, utils } from "ethers";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { increaseTo, latest } from "./helpers/block-traveller";
import { setUp } from "./test-setup";

const { defaultAbiCoder } = utils;

describe("Timelock", () => {
  // Exchange contracts
  let looksRareExchange: Contract;
  let timelock: Contract;

  // Other global variables
  let standardProtocolFee: BigNumber;
  let royaltyFeeLimit: BigNumber;
  let accounts: SignerWithAddress[];
  let admin: SignerWithAddress;
  let feeRecipient: SignerWithAddress;
  let royaltyCollector: SignerWithAddress;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    admin = accounts[0];
    feeRecipient = accounts[19];
    royaltyCollector = accounts[15];
    standardProtocolFee = BigNumber.from("200");
    royaltyFeeLimit = BigNumber.from("9500"); // 95%

    [, , , , , , , , , , , looksRareExchange, , , , , , , , ,] = await setUp(
      admin,
      feeRecipient,
      royaltyCollector,
      standardProtocolFee,
      royaltyFeeLimit
    );

    const Timelock = await ethers.getContractFactory("Timelock");
    timelock = await Timelock.deploy(admin.address, 1209600);
    await timelock.deployed();
    await looksRareExchange.transferOwnership(timelock.address);
  });

  describe("Timelock owners", async () => {
    it("Timelock contract can transfer exchange ownership to other address", async () => {
      const value = 0;
      const signature = "transferOwnership(address)";
      const newAdmin = accounts[5].address;

      // Fee recipient encoded
      const data = defaultAbiCoder.encode(["address"], [newAdmin]);

      const eta = BigNumber.from(await latest())
        .add(await timelock.delay())
        .add(5000000);

      await timelock.connect(admin).queueTransaction(looksRareExchange.address, value, signature, data, eta);
      await increaseTo(eta);

      await timelock.connect(admin).executeTransaction(looksRareExchange.address, value, signature, data, eta);
      assert.equal(await looksRareExchange.owner(), newAdmin);
    });

    it("Timelock contract cannot transfer exchange before ETA", async () => {
      const value = 0;
      const signature = "transferOwnership(address)";
      const newAdmin = accounts[5].address;

      // Fee recipient encoded
      const data = defaultAbiCoder.encode(["address"], [newAdmin]);

      const eta = BigNumber.from(await latest())
        .add(await timelock.delay())
        .add(5000000);

      await timelock.connect(admin).queueTransaction(looksRareExchange.address, value, signature, data, eta);
      await increaseTo(eta.sub(1));

      await expect(
        timelock.connect(admin).executeTransaction(looksRareExchange.address, value, signature, data, eta)
      ).to.be.revertedWith("Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    });

    it("Timelock contract cannot transfer exchange after ETA + grace period", async () => {
      const value = 0;
      const signature = "transferOwnership(address)";
      const newAdmin = accounts[5].address;

      // Fee recipient encoded
      const data = defaultAbiCoder.encode(["address"], [newAdmin]);

      const eta = BigNumber.from(await latest())
        .add(await timelock.delay())
        .add(5000000);

      await timelock.connect(admin).queueTransaction(looksRareExchange.address, value, signature, data, eta);
      await increaseTo(eta.add(await timelock.GRACE_PERIOD()).add(1));

      await expect(
        timelock.connect(admin).executeTransaction(looksRareExchange.address, value, signature, data, eta)
      ).to.be.revertedWith("Timelock::executeTransaction: Transaction is stale.");
    });

    it("Queuing is only callable by the timelock", async () => {
      const notAdminUser = accounts[3];
      const value = 0;
      const signature = "transferOwnership(address)";

      // Fee recipient encoded
      const data = defaultAbiCoder.encode(["address"], [notAdminUser.address]);

      const eta = BigNumber.from(await latest())
        .add(await timelock.delay())
        .add(1);

      await expect(
        timelock.connect(notAdminUser).queueTransaction(looksRareExchange.address, value, signature, data, eta)
      ).to.be.revertedWith("Timelock::queueTransaction: Call must come from admin.");
    });

    it("Executing is only callable by the timelock", async () => {
      const notAdminUser = accounts[3];
      const value = 0;
      const signature = "transferOwnership(address)";

      // Fee recipient encoded
      const data = defaultAbiCoder.encode(["address"], [notAdminUser.address]);

      const eta = BigNumber.from(await latest())
        .add(await timelock.delay())
        .add(1);

      await timelock.connect(admin).queueTransaction(looksRareExchange.address, value, signature, data, eta);
      await increaseTo(eta);

      await expect(
        timelock.connect(notAdminUser).executeTransaction(looksRareExchange.address, value, signature, data, eta)
      ).to.be.revertedWith("Timelock::executeTransaction: Call must come from admin.");
    });

    it("Cannot accept admin if sender is not pendingAdmin", async () => {
      const notAdminUser = accounts[3];

      await expect(timelock.connect(notAdminUser).acceptAdmin()).to.be.revertedWith(
        "Timelock::acceptAdmin: Call must come from pendingAdmin."
      );
    });

    it("Cannot set admin without timelocking", async () => {
      await expect(timelock.connect(admin).setPendingAdmin(admin.address)).to.be.revertedWith(
        "Timelock::setPendingAdmin: Call must come from Timelock."
      );
    });

    it("Cannot change admin without timelocking", async () => {
      await expect(timelock.connect(admin).setDelay("120000")).to.be.revertedWith(
        "Timelock::setDelay: Call must come from Timelock."
      );
    });
  });
});
