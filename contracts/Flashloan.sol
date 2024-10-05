//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract FlashloanArbitrageV3 is FlashLoanSimpleReceiverBase {
    address private immutable owner;
    ISwapRouter public immutable uniswapV3Router;
    IUniswapV2Router02 public immutable sushiswapRouter;
    IQuoter public immutable quoter;
    address private immutable WETH;
    address private immutable DAI;

    // Define multiple fee tiers for Uniswap V3
    uint24[] public uniswapV3Fees = [500, 3000, 10000]; // 0.05%, 0.3%, 1%

    error Unauthorized();
    error NotProfitable();
    error TransferFailed();
    error UnsupportedAsset();

    constructor(
        address _addressProvider,
        address _weth,
        address _dai,
        address _uniswapV3Router,
        address _sushiswapRouter,
        address _quoterAddress
    )
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        owner = msg.sender;
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        sushiswapRouter = IUniswapV2Router02(_sushiswapRouter);
        quoter = IQuoter(_quoterAddress);
        WETH = _weth;
        DAI = _dai;
    }

    /**
     * @dev This function is called after the contract has received the flash loaned amount.
     * It performs arbitrage between Uniswap V3 and Sushiswap V2 and ensures that the loan can be repaid.
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address, // initiator
        bytes calldata // params
    ) external override returns (bool) {
        // Ensure the asset is WETH
        if (asset != WETH) revert UnsupportedAsset();

        uint256 amountOwed = amount + premium;

        // Get the amount of DAI we can get for WETH on both exchanges
        uint256 amountOutUniswap = getAmountOutUniswap(WETH, DAI, amount);
        uint256 amountOutSushiswap = getAmountOutSushiswap(WETH, DAI, amount);

        uint256 finalAmount;

        // Decide which exchange to use first based on better rates
        if (amountOutUniswap > amountOutSushiswap) {
            // Swap WETH to DAI on Uniswap V3
            uint256 daiAmount = swapUniswapV3(WETH, DAI, amount);

            // Swap DAI back to WETH on Sushiswap V2
            finalAmount = swapSushiswap(DAI, WETH, daiAmount);
        } else if (amountOutSushiswap > amountOutUniswap) {
            // Swap WETH to DAI on Sushiswap V2
            uint256 daiAmount = swapSushiswap(WETH, DAI, amount);

            // Swap DAI back to WETH on Uniswap V3
            finalAmount = swapUniswapV3(DAI, WETH, daiAmount);
        } else {
            // No profitable arbitrage opportunity
            revert NotProfitable();
        }

        // Ensure we have enough WETH to repay the flash loan
        if (finalAmount < amountOwed) {
            revert NotProfitable();
        }

        // Approve the POOL to pull the owed amount
        IERC20(asset).approve(address(POOL), amountOwed);

        // Transfer any remaining profit to the owner
        uint256 profit = finalAmount - amountOwed;
        if (profit > 0) {
            bool success = IERC20(asset).transfer(owner, profit);
            if (!success) revert TransferFailed();
        }

        return true;
    }

    /**
     * @notice Estimates the amount of `tokenOut` received for a given `amountIn` of `tokenIn` using Uniswap V3.
     * Dynamically selects the best fee tier based on maximum output.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of `tokenIn` to swap.
     * @return amountOut The estimated amount of `tokenOut` received.
     */
    function getAmountOutUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) { // 'view' modifier removed
        uint24 bestFee = 0;
        uint256 bestAmountOut = 0;

        for (uint256 i = 0; i < uniswapV3Fees.length; i++) {
            try quoter.quoteExactInputSingle(
                tokenIn,
                tokenOut,
                uniswapV3Fees[i],
                amountIn,
                0
            ) returns (uint256 quotedAmountOut) {
                if (quotedAmountOut > bestAmountOut) {
                    bestAmountOut = quotedAmountOut;
                    bestFee = uniswapV3Fees[i];
                }
            } catch {
                // If the quote fails for a particular fee, continue to the next
                continue;
            }
        }

        if (bestAmountOut == 0) {
            revert("getAmountOutUniswap: No valid quote found");
        }

        amountOut = bestAmountOut;

        // If bestFee remains 0, default to the most common fee
        if (bestFee == 0) {
            bestFee = 3000; // 0.3%
        }
    }

    /**
     * @dev Swaps tokens on Uniswap V3 using exactInputSingle with the optimal fee tier determined by getAmountOutUniswap.
     */
    function swapUniswapV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        // Approve the router to spend tokens
        IERC20(tokenIn).approve(address(uniswapV3Router), amountIn);

        // Determine the best fee tier
        uint256 estimatedAmountOut = getAmountOutUniswap(tokenIn, tokenOut, amountIn);
        uint24 optimalFee = bestFeeForAmountOut(tokenIn, tokenOut, amountIn, estimatedAmountOut);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: optimalFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 1, // Accept any amountOut
                sqrtPriceLimitX96: 0 // No price limit
            });

        amountOut = uniswapV3Router.exactInputSingle(params);
    }

    /**
     * @notice Determines the fee tier that provided the best output.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of `tokenIn` to swap.
     * @param targetAmountOut The target amount of `tokenOut` to achieve.
     * @return bestFee The fee tier that yielded the `targetAmountOut`.
     */
    function bestFeeForAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 targetAmountOut
    ) internal view returns (uint24 bestFee) {
        for (uint256 i = 0; i < uniswapV3Fees.length; i++) {
            uint24 fee = uniswapV3Fees[i];
            try quoter.quoteExactInputSingle(
                tokenIn,
                tokenOut,
                fee,
                amountIn,
                0
            ) returns (uint256 quotedAmountOut) {
                if (quotedAmountOut == targetAmountOut) {
                    bestFee = fee;
                    break;
                }
            } catch {
                continue;
            }
        }

        // If bestFee remains 0, default to the most common fee
        if (bestFee == 0) {
            bestFee = 3000; // 0.3%
        }
    }

    /**
     * @dev Swaps tokens on Sushiswap V2.
     */
    function swapSushiswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        // Approve the router to spend tokens
        IERC20(tokenIn).approve(address(sushiswapRouter), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = sushiswapRouter.swapExactTokensForTokens(
            amountIn,
            1, // Accept any amountOut
            path,
            address(this),
            block.timestamp
        );

        amountOut = amounts[amounts.length - 1];
    }

    /**
     * @dev Estimates the output amount on Sushiswap V2.
     */
    function getAmountOutSushiswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        address[] memory path = getPathForSushiswap(tokenIn, tokenOut);
        uint256[] memory amounts = sushiswapRouter.getAmountsOut(amountIn, path);
        amountOut = amounts[amounts.length - 1];
    }

    /**
     * @dev Defines the path for a Sushiswap V2 swap.
     */
    function getPathForSushiswap(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }

    /**
     * @dev Initiates a flash loan.
     */
    function requestFlashLoan(uint256 _amount) external {
        if (msg.sender != owner) revert Unauthorized();

        bytes memory params = ""; // Optional parameters
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            address(this),
            WETH,
            _amount,
            params,
            referralCode
        );
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens mistakenly sent to the contract.
     */
    function withdraw(address token) external {
        if (msg.sender != owner) revert Unauthorized();

        uint256 balance = IERC20(token).balanceOf(address(this));
        bool success = IERC20(token).transfer(owner, balance);
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Fallback function to accept ETH.
     */
    receive() external payable {}
}