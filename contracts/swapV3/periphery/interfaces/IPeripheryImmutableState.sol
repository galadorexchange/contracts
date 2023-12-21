// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Galador V3 deployer
    function deployer() external view returns (address);

    /// @return Returns the address of the Galador V3 factory
    function factory() external view returns (address);

    /// @return Returns the codeHash of Galador V3 Pool
    function codeHash() external view returns (bytes32);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}
