import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("StakingPool", function () {
  async function deployToken() {
    const [owner] = await hre.ethers.getSigners();
    const PoolToken = await hre.ethers.getContractFactory("PoolToken");
    const poolToken = await PoolToken.deploy();
    return { poolToken };
  }

  async function deployStakingPool() {
    const [owner, otherAccount] = await hre.ethers.getSigners();
    const { poolToken } = await deployToken();
    const StakingPool = await hre.ethers.getContractFactory("StakingPool");
    const stakingPool = await StakingPool.deploy(poolToken);

    return { poolToken, stakingPool, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should Deploy properly",async function(){
       const { poolToken, stakingPool, owner, otherAccount }=await deployStakingPool()
       expect(await stakingPool.token()).to.equal(poolToken)
       expect(await poolToken.owner()).to.equal(owner)
    })
  });

  describe("Create Pool", function () {
    it("Should Create Pool",async function(){
       const { poolToken, stakingPool, owner, otherAccount }=await deployStakingPool()
       const minPool=hre.ethers.parseEther("5");
       const maxPool=hre.ethers.parseEther("10");
       const duration = 100800;


      
       await stakingPool.createPools(
        minPool,   
        maxPool,  
        duration,
     
    );
       expect(await stakingPool.totalPools()).to.equal(1)
    })

    it("Should emit event",async function(){
      const { poolToken, stakingPool, owner, otherAccount }=await deployStakingPool()
       const minPool=hre.ethers.parseEther("5");
       const maxPool=hre.ethers.parseEther("10");
       const duration = 100800;
     
      const totalPools=1

      expect(await stakingPool.createPools(
        minPool,   
        maxPool,  
        duration,
      )).to.emit(stakingPool,"PoolCreated").withArgs(owner,totalPools)
    })
  });

  describe("StakeToPool", function(){
    it("token staked",async function(){
      const { poolToken, stakingPool, owner, otherAccount }=await deployStakingPool()
       const minPool=hre.ethers.parseEther("5");
       const maxPool=hre.ethers.parseEther("10");
       const duration = 100800;

       const amountToStake=hre.ethers.parseEther("5");
     


       await stakingPool.createPools(
        minPool,   
        maxPool,  
        duration,
      );


    const totalPool = await stakingPool.totalPools()
  


     await poolToken.transfer(otherAccount,amountToStake);
     expect(await poolToken.balanceOf(otherAccount)).to.equal(amountToStake)

    await poolToken.connect(otherAccount).approve(stakingPool, amountToStake)


    await expect(stakingPool.connect(otherAccount).stakeToPool(totalPool, amountToStake))
        .to.emit(stakingPool, "Staked")
        .withArgs(otherAccount.address, amountToStake);
         
    })
  })

  // describe("Calculate Reward", function(){
  //   it("should return the correct reward for a valid stake",async function(){
  //     const { poolToken, stakingPool, owner, otherAccount }=await deployStakingPool()
  //     const minPool=hre.ethers.parseEther("5");
  //     const maxPool=hre.ethers.parseEther("10");
  //     const duration = 100800;

  //     const amountToStake=hre.ethers.parseEther("5");
    


  //     await stakingPool.createPools(
  //      minPool,   
  //      maxPool,  
  //      duration,
  //    );


  //  const totalPool = await stakingPool.totalPools()
 


  //   await poolToken.transfer(otherAccount,amountToStake);
  //   expect(await poolToken.balanceOf(otherAccount)).to.equal(amountToStake)

  //    await poolToken.connect(otherAccount).approve(stakingPool, amountToStake)
     
  //    await stakingPool.connect(otherAccount).stakeToPool(totalPool,amountToStake);


  //    const stakingDuration = 86400; 
  //       await network.provider.send("evm_increaseTime", [stakingDuration]);
  //       await network.provider.send("evm_mine");


  //       const rewardRate=BigInt(1e14);
  //       const userShare=(amountToStake * rewardRate)/amountToStake;
  //       const reward=(BigInt(stakingDuration) * rewardRate * userShare)/rewardRate;

        
  //       expect(await stakingPool.calculateReward(totalPool)).to.equal(reward)
  //   })
  // })
});
