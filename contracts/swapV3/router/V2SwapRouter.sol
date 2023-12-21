// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "../openzeppelin-3.4.2/token/ERC20/IERC20Ozep342.sol";
import "../core/libraries/LowGasSafeMath.sol";
import "../openzeppelin-3.4.2/utils/ReentrancyGuard.sol";

import "./interfaces/IV2SwapRouter.sol";
import "./base/ImmutableState.sol";
import "./base/PeripheryPaymentsWithFeeExtended.sol";
import "./libraries/Constants.sol";
import "../v2/interfaces/IGaladorPair.sol";

// import './libraries/SmartRouterHelper.sol';

interface ISwapRouterGaladorV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

/// @title Galador V2 Swap Router
/// @notice Router for stateless execution of swaps against Galador V2
abstract contract V2SwapRouter is
    IV2SwapRouter,
    ImmutableState,
    PeripheryPaymentsWithFeeExtended,
    ReentrancyGuard
{
    using LowGasSafeMath for uint256;

    // supports fee-on-transfer tokens
    // requires the initial amount to have already been sent to the first pair
    // `refundETH` should be called at very end of all swaps
    function _swap(address[] memory path, address _to) private {
        require(path.length == 2, "Path is not 2");

        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);

            (address token0, ) = __sortTokens(input, output);
            IGaladorPair pair = IGaladorPair(
                __pairFor(factoryV2, input, output)
            );
            uint256 amountInput;
            uint256 amountOutput;
            // scope to avoid stack too deep errors
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20Ozep342(input).balanceOf(address(pair)).sub(
                    reserveInput
                );
                amountOutput = __getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? __pairFor(factoryV2, output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @inheritdoc IV2SwapRouter
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable override nonReentrant returns (uint256 amountOut) {
        IERC20Ozep342 srcToken = IERC20Ozep342(path[0]);
        IERC20Ozep342 dstToken = IERC20Ozep342(path[path.length - 1]);

        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            amountIn = srcToken.balanceOf(address(this));
        }

        pay(
            address(srcToken),
            hasAlreadyPaid ? address(this) : msg.sender,
            __pairFor(factoryV2, address(srcToken), path[1]),
            amountIn
        );

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        uint256 balanceBefore = dstToken.balanceOf(to);

        _swap(path, to);

        amountOut = dstToken.balanceOf(to).sub(balanceBefore);
        require(amountOut >= amountOutMin);
    }

    /// @inheritdoc IV2SwapRouter
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable override nonReentrant returns (uint256 amountIn) {
        address srcToken = path[0];

        amountIn = __getAmountsIn(factoryV2, amountOut, path)[0];
        require(amountIn <= amountInMax);

        pay(
            srcToken,
            msg.sender,
            __pairFor(factoryV2, srcToken, path[1]),
            amountIn
        );

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        _swap(path, to);
    }

    function __sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB);
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0));
    }

    function __pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = __sortTokens(tokenA, tokenB);
        // (,bytes memory data) = factory.call(abi.encodeWithSignature("getPair(address,address)", token0, token1)));
        // pair = abi.decode(data, (address));
        pair = ISwapRouterGaladorV2Factory(factory).getPair(token0, token1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function __getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0);
        uint256 amountInWithFee = amountIn.mul(9975);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function __getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0);
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function __getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2);
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = __getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = __getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function __getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = __sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IGaladorPair(
            __pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}
