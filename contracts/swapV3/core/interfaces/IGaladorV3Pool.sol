// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IGaladorV3PoolImmutables.sol";
import "./pool/IGaladorV3PoolState.sol";
import "./pool/IGaladorV3PoolDerivedState.sol";
import "./pool/IGaladorV3PoolActions.sol";
import "./pool/IGaladorV3PoolOwnerActions.sol";
import "./pool/IGaladorV3PoolEvents.sol";

/// @title The interface for a Galador V3 Pool
/// @notice A Galador pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IGaladorV3Pool is
    IGaladorV3PoolImmutables,
    IGaladorV3PoolState,
    IGaladorV3PoolDerivedState,
    IGaladorV3PoolActions,
    IGaladorV3PoolOwnerActions,
    IGaladorV3PoolEvents
{}
