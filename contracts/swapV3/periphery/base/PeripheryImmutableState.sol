// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "../interfaces/IPeripheryImmutableState.sol";

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override deployer;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;
    /// @dev Code hash
    bytes32 public immutable override codeHash;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;

    constructor(
        address _deployer,
        address _factory,
        address _WETH9,
        bytes32 _codeHash
    ) {
        deployer = _deployer;
        factory = _factory;
        WETH9 = _WETH9;
        codeHash = _codeHash;
    }
}
