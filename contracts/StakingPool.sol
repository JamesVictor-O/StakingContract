// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "./interface/IERC20.sol";
import { Error } from "./libraries/Error.sol";
import { Event } from "./libraries/Event.sol";


contract StakingPool {
    IERC20 public token;
    address public owner;
    uint256 public totalPools;
    uint constant private Max_PooL=6;

    constructor(address _tokenAddress){
        token = IERC20(_tokenAddress);
        owner = msg.sender;
    }
    
    struct PoolInfo{
        address creator;
        uint minAmountToStake;
        uint maxAmountToStake;
        uint stackDuration;
        uint startTime;
        uint totalAmountstaked;
    }

    struct Staker{
        uint amount;
        uint  timeStaked;
    }

    mapping(uint => PoolInfo) public stakingPools; // mapping for pools
    mapping(uint => mapping(address => Staker)) public userStakes; // mapping for address who stack
    mapping(uint256 => uint256) public totalTokenStaked; //  total amount staked in a po
    
    //  modifiers

    modifier OnlyOwner(){
        require(msg.sender == owner, "Only owner can create pool");
        _;
    }


    // create pools
    function createPools(uint _minStakeAmount, uint _maxStakeAmount, uint _duration) external OnlyOwner{
        if( _minStakeAmount <= 0) revert  Error.MinAmountLow();
        if(_maxStakeAmount <= 0) revert   Error.MaxAmountLow();
        if( _duration  < block.timestamp) revert Error.InvalidDuration();
        if(totalPools > Max_PooL-1) revert Error.PoolMax();

        totalPools++;

        stakingPools[totalPools] = PoolInfo({
            creator:msg.sender,
            minAmountToStake:_minStakeAmount,
            maxAmountToStake:_maxStakeAmount,
            stackDuration:block.timestamp + _duration,
            startTime:block.timestamp,
             totalAmountstaked: 0
        });

      emit Event.PoolCreated(msg.sender, totalPools);
    }


    // function stack in a pool

    function stakeToPool(uint _poolID,uint _amountTostake) external {
         
        if (_poolID > totalPools) revert Error.InvalidPoolId();
        if (_amountTostake < stakingPools[_poolID].minAmountToStake) revert Error.AmountTooLow();
        if (_amountTostake > stakingPools[_poolID].maxAmountToStake) revert Error.AmountTooHigh();
       if (block.timestamp < stakingPools[_poolID].startTime) revert Error.StakingNotStarted();
    //    if (block.timestamp > stakingPools[_poolID].endTime) revert Error.StakingPeriodEnded();

        if (token.balanceOf(msg.sender) < _amountTostake) revert Error.InsufficientBalance();

        
        token.transferFrom(msg.sender, address(this), _amountTostake);
        stakingPools[_poolID].totalAmountstaked += _amountTostake;


        userStakes[_poolID][msg.sender]=Staker({
            amount: _amountTostake,
            timeStaked:block.timestamp
        });

        emit Event.Staked(msg.sender, _amountTostake);
    }

    // create distribute calculate reward

  function calculateReward(uint _poolID) public view returns (uint) {
    if (_poolID > totalPools) revert Error.InvalidPoolId();

    uint amountStaked = userStakes[_poolID][msg.sender].amount;
    if (amountStaked == 0) revert Error.NoStakeFound();

    uint startTime = userStakes[_poolID][msg.sender].timeStaked;
    uint totalAmountInPool = stakingPools[_poolID].totalAmountstaked;
    
    uint stakingDuration = block.timestamp - startTime;
    
    uint rewardRate = 1e6;  

    if (totalAmountInPool == 0) return 0; 

    uint userShare = (amountStaked * 1e18) / totalAmountInPool; // Scale up before division
    uint reward = (stakingDuration * rewardRate * userShare) / 1e18; // Scale down after multiplication

    return reward;
}


    function withdrawReward(uint _poolID) external{
       require(userStakes[_poolID][msg.sender].amount > 0,"You did not stake in this Pool");
       uint amountToWithdraw=calculateReward(_poolID);
       token.transfer(msg.sender,amountToWithdraw);

       userStakes[_poolID][msg.sender].timeStaked=block.timestamp;
    }

}
