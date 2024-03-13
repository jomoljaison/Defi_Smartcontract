// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./DefiLiabraries.sol";
// import "./proxy/UUPSAccessControlUpgradeable.sol";


contract DecentralisedSc is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    address public quoteAddress;
    address public panRouter;
    address public panFactory;
    address public sushiRouter;
    address public sushiFactory;

    address public safemoonRouter;
    address public safemoonFactory;

    address public uniswapRouter;
    address public uniswapFactory;

    IQuoter private quoter;
    address public feeReceiver;

    struct DecentralisedDetails {
        address factory;
        address router;
        string exchange;
        uint256 types;
    }
    uint24 public slippagePercent;

    mapping(uint256 => DecentralisedDetails) public exchageDetails;

   

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    address public _owner;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() private view  returns (address) {
        return _owner;
    }

    function _msgSender() internal view virtual override returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function initialize(
        address _quote,
        address _panRouter,
        address _panFactory,
        address _sushiRouter,
        address _sushiFactory,
        address _safemoonRouter,
        address _safemoonFactory,
        address _uniswapRouter,
        address _uniswapFactory,
        address _feeReceiver,
        uint24 _slippagePercent
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

     quoter = IQuoter(_quote);
        quoteAddress = _quote;
        panRouter = _panRouter;
        panFactory = _panFactory;
        sushiRouter = _sushiRouter;
        sushiFactory = _sushiFactory;
        safemoonRouter = _safemoonRouter;
        safemoonFactory = _safemoonFactory;
        uniswapRouter = _uniswapRouter;
        uniswapFactory = _uniswapFactory;
        feeReceiver = _feeReceiver;
        slippagePercent = _slippagePercent;
        _owner = msg.sender;

        
        //emit SetQuoteAddress(_quote);
        //emit SetPanRouter(_panRouter);
        //emit SetPanFactory(_panFactory);
        //emit SetSushiRouter(_sushiRouter);
        //emit SetSushiFactory(_sushiFactory);
        //emit SetSafemoonRouter(_safemoonRouter);
        //emit SetSafemoonFactory(_safemoonFactory);
        //emit SetUniswapRouter(_uniswapRouter);
        //emit SetUniswapFactory(_uniswapFactory);

        exchageDetails[0] = DecentralisedDetails(_panFactory, _panRouter, "Pancake", 2);

        exchageDetails[1] = DecentralisedDetails(_sushiFactory, _sushiRouter, "Sushiswap", 2);

        exchageDetails[2] = DecentralisedDetails(_safemoonFactory, _safemoonRouter, "Safemoon", 2);

        exchageDetails[3] = DecentralisedDetails(_uniswapFactory, _uniswapRouter, "Uniswap", 3);
    }

    function changeQuoteAddress(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != quoteAddress, "New destination must be different");

        address oldDestination = quoteAddress;
        quoteAddress = newDestination;
        //emit QuoterChanged(oldDestination, newDestination);
    }

    function changePanRouter(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != panRouter, "New destination must be different");

        address oldDestination = panRouter;
        panRouter = newDestination;
        exchageDetails[0] = DecentralisedDetails(panFactory, newDestination, "Pancake", 2);
        //emit PanRouterChanged(oldDestination, newDestination);
    }

    function changePanFactory(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != panFactory, "New destination must be different");

        address oldDestination = panFactory;
        panFactory = newDestination;
        exchageDetails[0] = DecentralisedDetails(newDestination, panRouter, "Pancake", 2);
        //emit PanFactoryChanged(oldDestination, newDestination);
    }

    function changeSushiRouter(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != sushiRouter, "New destination must be different");

        address oldDestination = sushiRouter;
        sushiRouter = newDestination;
        exchageDetails[1] = DecentralisedDetails(sushiFactory, newDestination, "Sushiswap", 2);
        //emit SushiRouterChanged(oldDestination, newDestination);
    }

    function changeSushiFactory(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != sushiFactory, "New destination must be different");

        address oldDestination = sushiFactory;
        sushiFactory = newDestination;
        exchageDetails[1] = DecentralisedDetails(newDestination, sushiRouter, "Sushiswap", 2);
        //emit SushiFactoryChanged(oldDestination, newDestination);
    }

    function changeSafemoonRouter(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != safemoonRouter, "New destination must be different");

        address oldDestination = safemoonRouter;
        safemoonRouter = newDestination;
        exchageDetails[2] = DecentralisedDetails(safemoonFactory, newDestination, "Safemoon", 2);
        //emit SafemoonRouterChanged(oldDestination, newDestination);
    }

    function changeSafemoonFactory(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != safemoonFactory, "New destination must be different");

        address oldDestination = safemoonFactory;
        safemoonFactory = newDestination;
        exchageDetails[2] = DecentralisedDetails(newDestination, safemoonRouter, "Safemoon", 2);
        //emit SafemoonFactoryChanged(oldDestination, newDestination);
    }

    function changeUniswapRouter(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != uniswapRouter, "New destination must be different");

        address oldDestination = uniswapRouter;
        uniswapRouter = newDestination;
        exchageDetails[3] = DecentralisedDetails(uniswapFactory, newDestination, "Uniswap", 3);
        //emit UniswapRouterChanged(oldDestination, newDestination);
    }

    function changeUniswapFactory(address newDestination) public onlyOwner {
        require(newDestination != address(0), "Invalid new destination");
        require(newDestination != uniswapFactory, "New destination must be different");

        address oldDestination = uniswapFactory;
        uniswapFactory = newDestination;
        exchageDetails[3] = DecentralisedDetails(newDestination, uniswapRouter, "Uniswap", 3);
        //emit UniswapFactoryChanged(oldDestination, newDestination);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function changeFeeReceiver(address _newFeeReceiver) public onlyOwner {
        feeReceiver = _newFeeReceiver; 
        //emit changeFeeReceiverChanged(feeReceiver);
    }

    function changeSlippagePercent(uint24 _newSlippagePercent) public onlyOwner  {
        slippagePercent = _newSlippagePercent; 
        //emit changeSlippagePecent(slippagePercent);
    }

    function getAmountOutMin(
        address router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public view returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] memory amountOutMins = IUniswapV2Router02(router).getAmountsOut(_amount, path);
        return amountOutMins[path.length - 1];
    }

    function getEstimateforV3(
        address tokenIn,
        address tokenOut,
        uint24  _fee,
        uint256 amount
    ) public payable returns (uint256) {
        
        uint160 sqrtPriceLimitX96 = 0;

        return quoter.quoteExactOutputSingle(tokenIn, tokenOut,  _fee, amount, sqrtPriceLimitX96);
    }

    function RouterApprove(
        address tokenA,
        address tokenB,
        address router1,
        address router2,
        uint256 amount
    ) external  whenNotPaused nonReentrant {
    
        IERC20(tokenA).approve(tokenA, amount);
        IERC20(tokenA).approve(router1, amount);
        IERC20(tokenA).approve(router2, amount);
        
        IERC20(tokenB).approve(tokenB, amount);
        IERC20(tokenB).approve(router2, amount);
        IERC20(tokenB).approve(router1, amount);
        //emit approveRouter(tokenA, tokenB, amount);
    }

    function estimateTwoDecentralisedTrade(
        address _router1,
        address _router2,
        address _token1,
        address _token2,
        uint256 _amount
    ) external view returns (uint256) {
        uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
        uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
        return amtBack2;
    }

    function tokenView(address token) public view returns (string memory symbol, uint256 decimals) {
        string memory symbal = IERC20Metadata(token).symbol();
        uint256 deci = IERC20Metadata(token).decimals();
        return (symbal, deci);
    }

    function getPair(
        address token0,
        address token1,
        address _panFactory,
        uint24 _fee,
        uint256 types

    ) public view returns (address pair) {
        if (types == 1) {
            address pair1 = IUniswapFactory(_panFactory).getPair(token0, token1);
            return (pair1);
        } else if (types == 3) {
            address pairs = IUniswapV3Pool(_panFactory).getPool(token0, token1, _fee);
            return pairs;
        }
    }


function swap(
        address router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) internal returns (uint256){
            address[] memory path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
               return IUniswapV2Router02(router).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                block.timestamp + 300
            )[1];
    }
    function swapV3(
        address router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        uint24 _fee,
        uint256 _amountOut
    ) internal returns (uint256) {
        uint256 slippage = _amountOut - ((_amountOut * slippagePercent) / 10000) ;
        IV3SwapRouter routerIn = IV3SwapRouter(router);
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _fee,
                recipient: address(this),
                amountIn: _amount,
                amountOutMinimum: slippage,
                sqrtPriceLimitX96: 0
            });
        uint256 value = routerIn.exactInputSingle(params);
        require(slippage <= value, "Amount Out Slippage Exceeds");
        return value;
    }
    function TwoDecentralisedTrade(
        uint256 _amount,
        address tokenA,
        address tokenB,
        address router1,
        address router2,
        uint256 percent,
        uint256 gasfee
    ) external whenNotPaused nonReentrant {
        require(_amount>0, "Amount Should Be Non Zero value");
        IERC20(tokenA).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 tradeAmount = swap(router1, tokenA, tokenB, _amount );
        uint256 endAmount = swap(router2, tokenB, tokenA, tradeAmount );
        require(
            endAmount > _amount && (endAmount - _amount)>gasfee,
            "End balance must exceed start balance."
        );
        /* Fee Collect */
        uint256 percentage = (((endAmount - _amount) * percent) / 10000);
        IERC20(tokenA).safeTransfer(feeReceiver, percentage);     // @audit - use safeTransfer for example USDT.
        IERC20(tokenA).safeTransfer(msg.sender, endAmount - percentage); // @audit - use safeTransfer for example USDT.
        //emit tradeEvent(  _amount,endAmount,endAmount - _amount);
    }
    function TwoDecentralisedTradeFromV2ToV3(
        uint256 _amount,
        address tokenA,
        address tokenB,
        address router1,
        address router2,
        uint256 percent,
        uint24 _fee,
        uint256 gasfee,
        uint256 _amountOut
    ) external whenNotPaused nonReentrant {
        require(_amount>0, "Amount Should Be Non Zero value");
        require(_fee>0, "Pair Fee Should Be Non Zero Value");
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), _amount); // @audit use safeTransferFrom
        uint256 tradeableAmount = swap(router1, tokenA, tokenB, _amount);
        uint256 endAmount = swapV3(router2, tokenB, tokenA, tradeableAmount,_fee,_amountOut);
        require(endAmount > _amount && (endAmount - _amount)>gasfee, "DecentralisedBot: endAmount must be greater than amount");
      
        /* Fee Collect */
        uint256 percentage = (((endAmount - _amount) * percent) / 10000);
        IERC20(tokenA).safeTransfer(feeReceiver, percentage);
        IERC20(tokenA).safeTransfer(msg.sender, endAmount - percentage);
        //emit tradeEvent(  _amount,endAmount, endAmount - _amount);
    }
    function TwoDecentralisedTradeFromV3ToV2(
        uint256 _amount,
        address tokenA,
        address tokenB,
        address router1,
        address router2,
        uint256 percent,
        uint24 _fee,
        uint256 gasfee,
        uint256 _amountOut
    ) external whenNotPaused nonReentrant {
      require(_amount>0, "Amount Should Be Non Zero value");
        require(_fee>0, "Invalid fee");
        IERC20(tokenA).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 tradeAmount = swapV3(router1, tokenA, tokenB, _amount,_fee, _amountOut );
        uint256 endAmount = swap(router2, tokenB, tokenA, tradeAmount);
        require(endAmount > _amount&& (endAmount - _amount)>gasfee, "DecentralisedBot: endAmount must be greater than amount");
        /* Fee Collect */
        uint256 percentage = (((endAmount - _amount) * percent) / 10000);
        IERC20(tokenA).safeTransfer(feeReceiver, percentage);     // @audit - use safeTransfer for example USDT.
        IERC20(tokenA).safeTransfer(msg.sender, endAmount - percentage); // @audit - use safeTransfer for example USDT.
        //emit tradeEvent(  _amount,endAmount, endAmount - _amount);
    }
}
