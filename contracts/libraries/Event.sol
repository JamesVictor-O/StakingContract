// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library Event {
    event PoolCreated(address _creator, uint id);
   event Staked(address _staker, uint _amount);
}