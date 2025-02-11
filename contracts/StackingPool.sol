// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "./interface/IERC20.sol";


contract StakingPool {
     IERC20 public token;
     address public owner;
    constructor(address _tokenAddress){
        token=IERC20(_tokenAddress);
        owner= msg.sender;
    }

    
    struct PoolInfo{
        address creator;
        uint minAmountToStack;
        uint maxAmountToStack;
        uint stackDuration;
        uint startTime;
        uint totalAmountstaked;
        IERC20  tokenType;

    }
    struct Staker{
        uint amount;
        uint  timeStaked;
    }
    //   mapping for pools
    mapping(uint => PoolInfo) public stakingPools;
    uint256 public totalPools;
    // mapping for address who stack
    mapping(uint => mapping(address => Staker)) userStakes;


    //  total amount staked in a po
    mapping(uint256 => uint256) public totalTokenStaked;

    // event 
   event PoolCreated(address _creator, uint id);
   event Staked(address _staker, uint _amount);

    // create pools
    function createPools(uint _minStackAmount, uint _maxStackAmount, uint _duration) external {
        totalPools++;
        stakingPools[totalPools]=PoolInfo({
            creator:msg.sender,
            minAmountToStack:_minStackAmount,
            maxAmountToStack:_maxStackAmount,
            totalAmountstaked: 0,
            stackDuration:block.timestamp + _duration,
            startTime:block.timestamp,
            tokenType:token
        });

      emit PoolCreated(msg.sender, totalPools);
    }


    // function stack in a pool

    function stakeToPool(uint _poolID,uint _amountTostake) external {
        require(_poolID <= totalPools, "Invalid Poll, Pool has not been created");
        require(_amountTostake > 0, "Can't stack zero");
        require(_amountTostake >= stakingPools[_poolID].minAmountToStack, "Amount to low to be stacked In this Pool");
        require(_amountTostake <= stakingPools[_poolID].maxAmountToStack, "Amount to High to be stacked In this Pool");
        require(block.timestamp <= stakingPools[_poolID].stackDuration, "Staking period has ended"); 
        require(token.balanceOf(msg.sender) <= _amountTostake, "Insufficient Balance");
        
        token.transferFrom(msg.sender, address(this), _amountTostake);
        stakingPools[_poolID].totalAmountstaked += _amountTostake;


        userStakes[_poolID][msg.sender]=Staker({
            amount: _amountTostake,
            timeStaked:block.timestamp
        });

        emit Staked(msg.sender, _amountTostake);
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
