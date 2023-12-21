// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./interfaces/IGaladorV3PoolDeployer.sol";

import "./GaladorV3Pool.sol";

contract GaladorV3PoolDeployer is IGaladorV3PoolDeployer {
    bytes constant creationCode = type(GaladorV3Pool).creationCode;
    bytes32 constant initCodePairHash =
        keccak256(abi.encodePacked(creationCode));

    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    /// @inheritdoc IGaladorV3PoolDeployer
    Parameters public override parameters;

    address public factoryAddress;

    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "factory");
        _;
    }

    function setFactoryAddress(address _factoryAddress) external {
        require(factoryAddress == address(0), "initialized");

        factoryAddress = _factoryAddress;
    }

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    function deploy(
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) external override onlyFactory returns (address pool) {
        bytes memory bytecode = creationCode;
        bytes32 salt = keccak256(abi.encode(token0, token1, fee));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        GaladorV3Pool(pool).initialize(
            factoryAddress,
            token0,
            token1,
            fee,
            tickSpacing
        );
    }
}
