// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// import "https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol";

import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";
import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/IQuoter.sol";

pragma abicoder v2;

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

interface IUniswapV3Pool {
   function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
    function positions(bytes32 key) external view returns (uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function getPool( address tokenA,address tokenB,uint24 fee) external view returns (address pool);
}
interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
  
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function safeApprove(
        address spender,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}




interface UniswapV3Pool{
  function liquidity()external view returns(uint128);

}

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}


contract MydexV3 
{
   IUniswapV3Pool public UniswapFactori =IUniswapV3Pool(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    // 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60   tokenA
    // 0x326C977E6efc84E512bB9C30f76E30c160eD06FB   LINK 
    // 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6   WETH

    function getPools(address tokenA,address tokenb,address factory1,uint24 fees) external view returns (address pair,uint128 liquidity)
    {
        IUniswapV3Pool factry = IUniswapV3Pool(factory1);
        address pairAddress = factry.getPool(tokenA, tokenb,fees);

        UniswapV3Pool pool=UniswapV3Pool(pairAddress);
        uint128 liquiditi=pool.liquidity();
        return (pairAddress,liquiditi);
    }

   address admin = 0xff28322e1fD7B3dFc5b6A7588acbA947cFB98116;
   uint256 private liquidLimit=100000;






    function updateadmin(address user) public returns (address old, address latest) {
        require(msg.sender == admin);
        admin = user;
        return (admin, user);
    }


    function updateLimit(uint256  limit) public returns (uint256 limits) {
        require(msg.sender == admin);
        liquidLimit = limit;
        return (liquidLimit);
    }

    function swapExactInputSingle(uint256 amountIn,address tokenA,address tokenB,uint24 poolFee,uint24 fees) external returns (uint256 amountOut) {
     
        address pairAddress = UniswapFactori.getPool(tokenA, tokenB,fees);
        UniswapV3Pool pool=UniswapV3Pool(pairAddress);
        uint128 liquiditi=pool.liquidity();

        require(liquiditi > liquidLimit,"pair dont have enough liquidity");
        // msg.sender must approve this contract

        // Transfer the specified amount of tokenA to this contract.
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountIn);

        // Approve the router to spend tokenA.
        TransferHelper.safeApprove(tokenA, address(uniswapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenA,
                tokenOut: tokenB,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = uniswapRouter.exactInputSingle(params);
    }






}













// 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
// 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

// GOERLI

//https://goerli.etherscan.io/address/0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f#code   //uniswap  factory

//https://goerli.etherscan.io/address/0x4648a43b2c14da09fdf82b161150d3f634f40491#code     router uniswap
//https://goerli.etherscan.io/tx/0xbe8d7cd60fe0db122d6b19fce15ad0fd875c5bcc6e15b766dd4eced9dab240c7 tx uniswap
//https://goerli.etherscan.io/address/0x1F98431c8aD98523631AE4a59f267346ea31F984       factory uniswap
//https://goerli.etherscan.io/address/0xE592427A0AEce92De3Edee1F18E0157C05861564#readContract swap router

//https://goerli.etherscan.io/address/0x9a489505a00ce272eaa5e07dba6491314cae3796#readContract //router pancake
//https://goerli.etherscan.io/tx/0x252a33bb3a9b2130e1f09c3edf8ba61e85655f5163a82d497fa9fa1ffd82064d   tx pancake
//https://goerli.etherscan.io/address/0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865  factory  pancake

// https://goerli.etherscan.io/address/0x1b02da8cb0d097eb8d57a175b88c7d8b47997506#code  router sushiswap
// https://goerli.etherscan.io/tx/0x380a3a62053116a5d7273ba8fccd54330650e952e4aece45f0d195d810d7b677  tx sushiswap
// https://goerli.etherscan.io/address/0xc35DADB65012eC5796536bD9864eD8773aBc74C4#code   factory sushiswap   v2
