// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "./interface/IERC20.sol";
import { Error } from "./libraries/Error.sol";
import { Event } from "./libraries/Event.sol";


contract StakingPool {
    IERC20 public token;
    address public owner;

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
        IERC20  tokenType;
    }

    struct Staker{
        uint amount;
        uint  timeStaked;
    }

    mapping(uint => PoolInfo) public stakingPools; // mapping for pools
    uint256 public totalPools;
    mapping(uint => mapping(address => Staker)) userStakes; // mapping for address who stack
    mapping(uint256 => uint256) public totalTokenStaked; //  total amount staked in a po

    // create pools
    function createPools(uint _minStakeAmount, uint _maxStakeAmount, uint _duration) external {
        require( _minStakeAmount > 0, Error.MinAmountLow());
        require( _maxStakeAmount > 0, Error.MaxAmountLow());
        require( _duration > block.timestamp, Error.InvalidDuration());
        require(_maxStakeAmount > _minStakeAmount, Error.MaxAmountSHouldBeGreaterThanMin());

        totalPools++;

        stakingPools[totalPools] = PoolInfo({
            creator:msg.sender,
            minAmountToStake:_minStakeAmount,
            maxAmountToStake:_maxStakeAmount,
            totalAmountstaked: 0,
            stackDuration:block.timestamp + _duration,
            startTime:block.timestamp,
            tokenType:token
        });

      emit Event.PoolCreated(msg.sender, totalPools);
    }


    // function stack in a pool

    function stakeToPool(uint _poolID,uint _amountTostake) external {
         
        if (_poolID > totalPools) revert Error.InvalidPoolId();
        if (_amountTostake < stakingPools[_poolID].minAmountToStake) revert Error.AmountTooLow();
        if (_amountTostake > stakingPools[_poolID].maxAmountToStake) revert Error.AmountTooHigh();
        if (block.timestamp > stakingPools[_poolID].stackDuration) revert Error.StakingPeriodEnded();

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

    function calculateReward(uint _poolID) public view returns(uint){
        uint amountStaked=userStakes[_poolID][msg.sender].amount;
        uint durationOfStaking=userStakes[_poolID][msg.sender].timeStaked;
        uint totalAmountInPool=stakingPools[_poolID].totalAmountstaked;
        
        uint stakingDuration = block.timestamp - durationOfStaking;

          uint rewardRate = 1e14;

          uint userShare=(amountStaked * rewardRate)/totalAmountInPool;

          uint reward= (stakingDuration * rewardRate *userShare)/1e14;

          return reward;
    }

    function withdrawReward(uint _poolID) external{
       require(userStakes[_poolID][msg.sender].amount > 0,"You did not stack in this Pool");
       uint amountToWithdraw=calculateReward(_poolID);
       token.transfer(msg.sender,amountToWithdraw);

       userStakes[_poolID][msg.sender].timeStaked=block.timestamp;
    }

}
