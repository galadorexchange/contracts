// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract RestrictedERC20 is ERC20, ERC20Permit {
    using SafeERC20 for IERC20;
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) ERC20(name, symbol) ERC20Permit(name) {
        minter = msg.sender;
        _mint(msg.sender, totalSupply);
    }

    function mint(address _who, uint256 _amount) external onlyMinter {
        _mint(_who, _amount);
    }

    function changeMinter(address _minter) external onlyMinter {
        minter = _minter;
    }
}
