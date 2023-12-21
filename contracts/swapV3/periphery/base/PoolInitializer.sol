// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "../../core/interfaces/IGaladorV3Factory.sol";
import "../../core/interfaces/IGaladorV3Pool.sol";

import "./PeripheryImmutableState.sol";
import "../interfaces/IPoolInitializer.sol";

/// @title Creates and initializes V3 Pools
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        // require(token0 < token1);
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pool = IGaladorV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = IGaladorV3Factory(factory).createPool(token0, token1, fee);
            IGaladorV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IGaladorV3Pool(pool)
                .slot0();
            if (sqrtPriceX96Existing == 0) {
                IGaladorV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}
