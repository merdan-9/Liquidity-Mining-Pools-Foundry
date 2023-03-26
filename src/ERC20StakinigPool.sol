// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Clone} from "./lib/Clone.sol";
import {FullMath} from "./lib/FullMath.sol";
import {Multicall} from "./lib/Multicall.sol";
import {Ownable} from "./lib/Ownable.sol";
import {SelfPermit} from "./lib/SelfPermit.sol";

/// @title ERC20StakingPool
/// @author zefram.eth
/// @notice A modern, gas optimized staking pool contract for rewarding ERC20 stakers
/// with ERC20 tokens periodically and continuously
contract ERC20StakingPool is Ownable, Clone, Multicall, SelfPermit {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_ZeroOwner();
    error Error_AlreadyInitialized();
    error Error_NotRewardDistributor();
    error Error_AmountTooLarge();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardAdded(uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant PRECISION = 1e30;

    /// -----------------------------------------------------------------------
    /// Storage variable
    /// -----------------------------------------------------------------------

    /// @notice The last Unix timestamp (in seconds) when rewardPerTokenStored was updated
    uint256 public lastUpdateTime;
    /// @notice The total tokens staked in the pool
    uint256 public totalSupply;
    /// @notice The Unix timestamp (in seconds) at which the current reward period ends
    uint256 public periodFinish;
    /// @notice The per-second rate at which rewardPerToken increases
    uint256 public rewardRate;
    /// @notice The last stored rewardPerToken value
    uint256 public rewardPerTokenStored;

    /// @notice Tracks if an address can call notifyReward()
    mapping(address => bool) isRewardDistributor;
    /// @notice The amount of tokens staked by an account
    mapping(address => uint256) balanceOf;
    /// @notice The rewardPerToken value when an account last staked/withdrew/withdrew rewards
    mapping(address => uint256) userRewardPerTokenPaid;
    /// @notice The earned() value when an account last staked/withdrew/withdrew rewards
    mapping(address => uint256) rewards;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The token being rewarded to stakers
    function rewardToken() public pure returns (ERC20 rewardToken_) {
        return ERC20(_getArgAddress(0));
    }

    /// @notice The token being staked in the pool
    function stakeToken() public pure returns (ERC20 stakeToken_) {
        return ERC20(_getArgAddress(0x14));
    }

    /// @notice The length of each reward period, in seconds
    function DURATION() public pure returns (uint64 DURATION_) {
        return _getArgUint64(0x28);
    }

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    /// @notice Initializes the owner, called by StakingPoolFactory
    /// @param initialOwner The initial owner of the contract
    function initialize(address initialOwner) external {
        if (owner() != address(0)) {
            revert Error_AlreadyInitialized();
        }
        if (initialOwner == address(0)) {
            revert Error_ZeroOwner();
        }
        _transferOwnership(initialOwner);
    }


    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Stakes tokens in the pool to earn rewards
    /// @param amount The amount of tokens to stake
    function stake(uint256 amount) external {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (amount == 0) {
            return;
        }

        /// -----------------------------------------------------------------------
        /// Storage loads
        /// -----------------------------------------------------------------------

        uint256 accountBalance = balanceOf[msg.sender];
        uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
        uint256 totalSupply_ = totalSupply;
        uint256 rewardPerToken_ = _rewardPerToken(totalSupply_, lastTimeRewardApplicable_, rewardRate);

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue rewards
        rewardPerTokenStored = rewardPerToken_;
        lastUpdateTime = lastTimeRewardApplicable_;
        rewards[msg.sender] = _earned(msg.sender, accountBalance, rewardPerToken_, rewards[msg.sender]);
        userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

        // stake
        totalSupply = totalSupply_ + amount;
        balanceOf[msg.sender] = accountBalance + amount;

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        stakeToken().transferFrom(msg.sender, address(this), amount);
        
        emit Staked(msg.sender, amount);
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    function lastTimeRewardApplicable() public view returns (uint64) {
        return uint64(block.timestamp < periodFinish ? uint64(block.timestamp) : periodFinish);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _earned(address account, uint256 accountBalance, uint256 rewardPerToken_, uint256 accountRewards)
        internal
        view
        returns (uint256)
    {
        return FullMath.mulDiv(accountBalance, rewardPerToken_ - userRewardPerTokenPaid[account], PRECISION)
            + accountRewards;
    }

    function _rewardPerToken(uint256 totalSupply_, uint64 lastTimeRewardApplicable_, uint256 rewardRate_)
        internal
        view
        returns (uint256)
    {
        if (totalSupply_ == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored
            + FullMath.mulDiv((lastTimeRewardApplicable_ - lastUpdateTime) * PRECISION, rewardRate_, totalSupply_);
    }

}