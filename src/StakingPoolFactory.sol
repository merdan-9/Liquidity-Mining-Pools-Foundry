// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.14;

import {ClonesWithImmutableArgs} from "./lib/ClonesWithImmutableArgs.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ERC20StakingPool} from "./ERC20StakingPool.sol";

/// @title StakingPoolFactory
/// @author zefram.eth
/// @notice Factory for deploying ERC20StakingPool and ERC721StakingPool contracts cheaply
contract StakingPoolFactory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event CreateERC20StakingPool(ERC20StakingPool stakingPool);

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The contract used as the template for all ERC20StakingPool contracts created
    ERC20StakingPool public immutable erc20StakingPoolImplementation;

    constructor(ERC20StakingPool erc20StakingPoolImplementation_) {
        erc20StakingPoolImplementation = erc20StakingPoolImplementation_;
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    /// @notice Creates an ERC20StakingPool contract
    /// @dev Uses a modified minimal proxy contract that stores immutable parameters in code and
    /// passes them in through calldata. See ClonesWithImmutableArgs.
    /// @param rewardToken The token being rewarded to stakers
    /// @param stakeToken The token being staked in the pool
    /// @param DURATION The length of each reward period, in seconds
    /// @return stakingPool The created ERC20StakingPool contract
    function createERC20StakingPool(ERC20 rewardToken, ERC20 stakeToken, uint64 DURATION)
        external
        returns (ERC20StakingPool stakingPool)
    {
        bytes memory data = abi.encodePacked(rewardToken, stakeToken, DURATION);

        stakingPool = ERC20StakingPool(address(erc20StakingPoolImplementation).clone(data));
        stakingPool.initialize(msg.sender);

        emit CreateERC20StakingPool(stakingPool);
    }
}