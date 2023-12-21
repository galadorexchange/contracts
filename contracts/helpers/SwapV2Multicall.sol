// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "../swapV2/interfaces/IGaladorPair.sol";

contract SwapV2Multicall {
    struct ReserveData {
        uint112 reserve0;
        uint112 reserve1;
    }

    function getMultiReserves(
        address[] memory pairs
    ) external view returns (ReserveData[] memory) {
        uint256 length = pairs.length;
        ReserveData[] memory balances = new ReserveData[](length);
        uint8 i;
        for (i = 0; i < length; i++) {
            address pair = pairs[i];
            if (pair != address(0)) {
                (uint112 reserve0, uint112 reserve1, ) = IGaladorPair(pair)
                    .getReserves();
                balances[i] = ReserveData(reserve0, reserve1);
            } else {
                balances[i] = ReserveData(0, 0);
            }
        }

        return balances;
    }
}
