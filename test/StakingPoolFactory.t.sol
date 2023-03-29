// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import {BaseTest, console} from "./base/BaseTest.sol";

import {TestERC20} from "./mocks/TestERC20.sol";

import {ERC20StakingPool} from "../src/ERC20StakingPool.sol";
import {StakingPoolFactory} from "../src/StakingPoolFactory.sol";

contract StakingPoolFactoryTest is BaseTest {
    StakingPoolFactory factory;
    TestERC20 rewardToken;
    TestERC20 stakeToken;

    function setUp() public {
        ERC20StakingPool erc20StakingPoolImplementation = new ERC20StakingPool();

        factory = new StakingPoolFactory(erc20StakingPoolImplementation);

        rewardToken = new TestERC20();
        stakeToken = new TestERC20();
    }

    /// -------------------------------------------------------------------
    /// Gas benchmarking
    /// -------------------------------------------------------------------

    function testGas_createERC20StakingPool(uint64 DURATION) public {
        factory.createERC20StakingPool(rewardToken, stakeToken, DURATION);
    }

    /// -------------------------------------------------------------------
    /// Correctness tests
    /// -------------------------------------------------------------------

    function testCorrectness_createERC20StakingPool(uint64 DURATION) public {
        ERC20StakingPool stakingPool = factory.createERC20StakingPool(rewardToken, stakeToken, DURATION);

        assertEq(address(stakingPool.rewardToken()), address(rewardToken));
        assertEq(address(stakingPool.stakeToken()), address(stakeToken));
        assertEq(stakingPool.DURATION(), DURATION);
    }
}


