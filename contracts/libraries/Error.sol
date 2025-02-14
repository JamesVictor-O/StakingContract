// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library Error {
    error InsufficientBalance();
    error AmountTooLow();
    error AmountTooHigh();
    error StakingPeriodNotEnded();
    error StakingPeriodEnded();
    error InvalidPoolId();
    error IsZero();
    error NoStakeFound();

    error StakingNotStarted();
    error MaxAmountSHouldBeGreaterThanMin();
    error MinAmountLow();
    error MaxAmountLow();
    error InvalidDuration();
    error PoolMax();
}