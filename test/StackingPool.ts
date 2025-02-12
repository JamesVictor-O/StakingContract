import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { assert } from "console";

describe("StakingPool", function () {
  async function deployPoolToken() {
    const [owner, staker1, staker2, staker3] = await hre.ethers.getSigners();
    const PoolToken = await hre.ethers.getContractFactory("PoolToken");
    const poolToken = await PoolToken.deploy();
    return { poolToken };
  }

  async function deployStakingPool() {
    const [owner, otherAccount] = await hre.ethers.getSigners();
    const { poolToken } = await deployPoolToken();
    const StakingPool = await hre.ethers.getContractFactory("StakingPool");

    const stakingPool = await StakingPool.deploy(poolToken);

    return { poolToken, stakingPool, owner, otherAccount };
  }

  describe("Deploy Staking Pool Contract", function () {
    it("Should deploy staking pool contract successfully and return actual contract owner",async function(){
       const {poolToken, stakingPool, owner} =await deployStakingPool()

       expect(await stakingPool.owner()).to.equal(owner)
    })

    it("Should fail if signer is not owner of contract",async function(){
      const {poolToken, stakingPool, owner, otherAccount} =await deployStakingPool()

      expect(await stakingPool.owner()).to.not.equal(otherAccount)
   })
  });

  describe("Test Create Pool Function", function () {
    it ("Should create a Pool if all conditions are met", async function () {
        const {poolToken, stakingPool, owner} = await deployStakingPool();

        const currentTimestamp = (await hre.ethers.provider.getBlock()).timestamp;
        const duration = currentTimestamp + (7 * 24 * 60 * 60); // 7 days duration

        expect(await stakingPool.totalPools()).to.equal(0)
        expect(await stakingPool.createPools(1, 2, duration)).to.emit(stakingPool, 'PoolCreated').withArgs(owner, 1);
        expect(await stakingPool.totalPools()).to.equal(1)
    })

    it ("Should not create a Pool if min amount is less than 1", async function () {
      const {poolToken, stakingPool, owner} = await deployStakingPool();
      const minAmount = 0;
      const maxAmount = 0;
      const duration = 0;

      await expect(stakingPool.createPools(minAmount, maxAmount, duration)).to.be.revertedWithCustomError(stakingPool, 'MinAmountLow');
  })

    it ("Should not create a Pool if max amount is less than 1", async function () {
        const {poolToken, stakingPool, owner} = await deployStakingPool();
        const minAmount = 1;
        const maxAmount = 0;
        const duration = 0;

        await expect(stakingPool.createPools(minAmount, maxAmount, duration)).to.be.revertedWithCustomError(stakingPool, 'MaxAmountLow');
    })

    it ("Should not create a Pool if duration is less than current time", async function () {
      // arrange
      const {poolToken, stakingPool, owner} = await deployStakingPool();
      const minAmount = 1;
      const maxAmount = 1;
      const duration = 0;

      expect(minAmount).to.equal(1);

      
      await expect(stakingPool.createPools(minAmount, maxAmount, duration)) //act
      .to.be.revertedWithCustomError(stakingPool, 'InvalidDuration'); // asserting
  })

  it ("Should not create a Pool if maxAmount < minAmount", async function () {
      const {poolToken, stakingPool, owner} = await deployStakingPool();
      const minAmount = 1;
      const maxAmount = 1;
      const currentTimestamp = (await hre.ethers.provider.getBlock()).timestamp;
        const duration = currentTimestamp + (7 * 24 * 60 * 60); // 7 days duration

      await expect(stakingPool.createPools(minAmount, maxAmount, duration)).to.be.revertedWithCustomError(stakingPool, 'MaxAmountSHouldBeGreaterThanMin');
  })

  })

  
});
