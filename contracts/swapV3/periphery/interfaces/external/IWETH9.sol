// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "../../../openzeppelin-3.4.2/token/ERC20/IERC20Ozep342.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20Ozep342 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;
    
    function depositMeTemp(uint256 value) external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}
