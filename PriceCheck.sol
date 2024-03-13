// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;
import "hardhat/console.sol";

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/uniswapv2/libraries/SafeMath.sol

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/uniswapv2/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint uniswaap) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uniswaap = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getNum_tkn(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint Num_tkn) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        Num_tkn = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint Num_tkn, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(Num_tkn > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(Num_tkn).mul(1000);
        uint denominator = reserveOut.sub(Num_tkn).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getNum_tkn calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getNum_tkn(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint Num_tkn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = Num_tkn;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/uniswapv2/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper mBNBods for interacting with ERC20 tokens and sending BNB that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function TKN_bnb() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint uniswaapDesired,
        uint amountAMin,
        uint uniswaapMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint uniswaap, uint liquidity);
    function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint uniswaapMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint uniswaap);
    function removeLiquidityBNB(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountBNB);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint uniswaapMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint uniswaap);
    function removeLiquidityBNBWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountBNB);
    function swapExactTokensForTokens(
        uint amountIn,
        uint Num_tknMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint Num_tkn,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactBNBForTokens(uint Num_tknMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactBNB(uint Num_tkn, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint Num_tknMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapBNBForExactTokens(uint Num_tkn, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint uniswaap);
    function getNum_tkn(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint Num_tkn);
    function getAmountIn(uint Num_tkn, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint Num_tkn, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityBNBSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountBNB);
    function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountBNB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint Num_tknMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint Num_tknMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint amountIn,
        uint Num_tknMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// File: contracts/uniswapv2/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/uniswapv2/interfaces/ITKN_bnb.sol

pragma solidity >=0.5.0;

interface ITKN_bnb {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}





// File: contracts/uniswapv2/UniswapV2Router02.sol

pragma solidity =0.6.12;



contract SWAP {
    using SafeMathUniswap for uint;

    address public  factory;
    address public panFactory;
    address public  TKN_bnb;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }
    // _factory     0xc35dadb65012ec5796536bd9864ed8773abc74c4     uniswap
    // _panFactory  0xb7926c0430afb07aa7defde6da862ae0bde767bc     pancake
    // TEST         0x70e509a6c9b6f7d8b9e92a21cad2830afeb7f374
    // WBNB         0xae13d989dac2f0debff460ac112a837c89baa7cd
    // CAKE         0xFa60D973F7642B748046464e165A65B7323b0DEE
    // BUSD         0xaB1a4d4f1D656d2450692D237fdD6C7f9146e814
    // DAI          0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867
    constructor(address _factory,address _panFactory, address _TKN_bnb) public {
        panFactory= _panFactory;
        factory = _factory;
        TKN_bnb = _TKN_bnb;
    }
    
    receive() external payable {
        assert(msg.sender == TKN_bnb); // only accept BNB via fallback from the TKN_bnb contract
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure  returns (uint256 uniswaap,uint256 amountsA) {
         uint256 total=( UniswapV2Library.quote(amountA, reserveA, reserveB));
         uint256 totala= (UniswapV2Library.quote(amountA, reserveA, reserveB));
         return (total,totala);
    }


////////////////////////////////////////📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️📌️//////////////////////////////////////////////////
    // uintswpa 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506



    function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router02(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
        
	}


       function getAmountOuttMinPNCAKE(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router02(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
        
	}


  

// ["0xae13d989dac2f0debff460ac112a837c89baa7cd","0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867"] wbnb,dai
//["0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867","0xae13d989dac2f0debff460ac112a837c89baa7cd"] dai,wbnb

     function getAmsoudtqsIn(uint256 amountOut, address[] memory path,address[] memory pathreverse )
        public    view
        returns (uint256[] memory susswapamounts,uint256[] memory Pancakeamount)
    {
         uint256[] memory total =(UniswapV2Library.getAmountsIn(factory, amountOut, path));
         uint256[] memory totala = (UniswapV2Library.getAmountsIn(panFactory, total[0], pathreverse));
         return (total,totala);
    }



    function getAmoudtqsIn(uint256 amountOut, address[] memory path,address[] memory pathreverse )
      public  view returns (uint256[] memory Pancakeswapamounts,uint256[] memory susswapamount)
    {
         uint256[] memory total =(UniswapV2Library.getAmountsIn(factory, amountOut, path));
         uint256[] memory totala = (UniswapV2Library.getAmountsIn(panFactory, total[0], pathreverse));
         return (total,totala);
    }




// ["0xae13d989dac2f0debff460ac112a837c89baa7cd","0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867"] wbnb,dai
//["0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867","0xae13d989dac2f0debff460ac112a837c89baa7cd"] dai,wbnb

    function getAmountsOut( uint256 uni, address[] memory path,uint256 pancake) public    view
              returns (uint256[] memory uniswapamounts,uint256[] memory pancakeamounts1)
    {
       uint256[] memory total =(UniswapV2Library.getAmountsOut(factory, uni, path));
       uint256[] memory totala= (UniswapV2Library.getAmountsOut(panFactory, pancake, path));
          return (total,totala);
    }

//uiniswap
    function getAmwountsInuniswap(uint256 Num_tkn, address[] memory path)
        public    view
      
        returns (uint256[] memory Uniswapamounts)
    {
         uint256[] memory total =(UniswapV2Library.getAmountsIn(factory, Num_tkn, path));
          return (total);
    }

//pancakeSwap
    function getAmwountsInPancake1(uint256 Num_tkn, address[] memory path)
        public    view
      
        returns (uint256[] memory Pancakeswapamounts)
    {
         uint256[] memory total =(UniswapV2Library.getAmountsIn(panFactory,Num_tkn, path));
          return (total);
    }


// path[0]=wbnb
// path[1]=dai
// [path[0],path[1]] BNB DAi
// [paths[0],paths[1]] DAi BNB


//["0xae13d989dac2f0debff460ac112a837c89baa7cd","0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867"]wbnb,dai
//["0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867","0xae13d989dac2f0debff460ac112a837c89baa7cd"]dai,wbnb


    function pricechecking01(uint256 minimum,address[] memory path,address [] memory paths) public view returns(string  memory ,uint256 [] memory ,uint256 [] memory  )
    {
        uint256[] memory bnb =(UniswapV2Library.getAmountsIn(factory, minimum, path)); //?bnb
        uint256[] memory dai=(UniswapV2Library.getAmountsIn(panFactory,bnb[0], paths)); //give  ?bnb (got ?dai)
        string memory  truee="output greaterthan input";
        string memory  ffalse="input  greater than output";
        if(dai[0]>minimum)
        {
            return (truee,dai,bnb);
        }
        else if(dai[0]<minimum)
        {
            uint256[] memory bnnb=(UniswapV2Library.getAmountsIn(factory, dai[0], path));//? bnnb
            uint256[] memory daai=(UniswapV2Library.getAmountsIn(factory, bnnb[0], paths));// give ?bnb (got ?dai)
         
            return (ffalse,bnnb,daai);
        }
      
        

    }

// path[0]=dai
// path[1]=BNB
// [path[0],path[1]] DAI BNB
// [paths[0],paths[1]] BNB DAI
// ["0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867","0xae13d989dac2f0debff460ac112a837c89baa7cd"]dai,wbnb
// ["0xae13d989dac2f0debff460ac112a837c89baa7cd","0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867"]wbnb,dai

    function pricechecking2(uint256 minimum,address[] memory path,address [] memory paths) public view returns(string memory ,uint256 [] memory ,uint256[] memory  )
    {
        uint256[] memory dai =(UniswapV2Library.getAmountsIn(factory, minimum, path)); //?dai
        uint256[] memory bnb=(UniswapV2Library.getAmountsIn(panFactory,dai[0], paths)); //give  ?dai (got ?bnb)
        string memory  truee="output greaterthan input";
        string memory  ffalse="input  greater than output";

        if(bnb[0]>minimum)
        {
            return (truee,bnb,dai); //"output greaterthan input";
                }
        else if(bnb[0]<minimum)
        {
            uint256[] memory daai=(UniswapV2Library.getAmountsIn(factory, bnb[0], path));//? daai
            uint256[] memory bnnb=(UniswapV2Library.getAmountsIn(factory, daai[0], paths));// give ?dai (got ?bnb)
        
             return(ffalse,bnnb,daai);
        }

    }


    address tracker_0x_DAI = 0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867;
    address tracker_0x_WNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
       //pancakerouter  0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // uintswparouter   0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506

        // TEST         0x70e509a6c9b6f7d8b9e92a21cad2830afeb7f374
    // WBNB         0xae13d989dac2f0debff460ac112a837c89baa7cd
    // CAKE         0xFa60D973F7642B748046464e165A65B7323b0DEE
    // BUSD         0xaB1a4d4f1D656d2450692D237fdD6C7f9146e814
    // DAI          0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867

 function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to,address pancake_router,address wbnb) external {
      
    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
    IERC20Uniswap(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    IERC20Uniswap(_tokenIn).approve(pancake_router, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == wbnb || _tokenOut == wbnb) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = wbnb;
      path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router01(pancake_router).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }

  

}
