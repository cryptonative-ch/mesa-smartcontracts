// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "dxswap-core/contracts/interfaces/IDXswapFactory.sol";
import "dxswap-periphery/contracts/interfaces/IDXswapRouter.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IWETH.sol";

contract PoolLiquidity {
    address public WETH;
    address public router;
    address public factory;
    address public tokenA;
    address public tokenB;
    address public pair;
    uint256 public amountA;
    uint256 public amountB;
    uint256 public locktime;
    uint256 public expirationDate;
    uint256 public liquidity;

    mapping(address => mapping(address => uint256)) public tokenBalances;
    mapping(address => uint256) public totals;

    function initPoolLiquidity(
        address _router,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _duration,
        uint256 _locktime,
        address _WETH
    ) external {
        router = _router;
        tokenA = _tokenA;
        tokenB = _tokenB;
        amountA = _amountA;
        amountB = _amountB;
        WETH = _WETH;
        factory = IDXswapRouter(router).factory();
        pair = IDXswapFactory(factory).getPair(_tokenA, _tokenB);
        if (pair == address(0)) {
            IDXswapFactory(factory).createPair(_tokenA, _tokenB);
        }
        expirationDate = block.timestamp + _duration;
        locktime = _locktime;
    }

    function deposit(uint256 _amountA, uint256 _amountB) external {
        require(block.timestamp < expirationDate, "PoolLiquidity: EXPIRED");
        require(liquidity == 0, "PoolLiquidity: LIQUIDITY_ALREADY_PROVIDED");
        TransferHelper.safeTransfer(tokenA, address(this), _amountA);
        TransferHelper.safeTransfer(tokenB, address(this), _amountB);
        tokenBalances[tokenA][msg.sender] += _amountA;
        tokenBalances[tokenB][msg.sender] += _amountB;
        totals[tokenA] += _amountA;
        totals[tokenB] += _amountB;
    }

    function provideLiquidity() external {
        require(block.timestamp < expirationDate, "PoolLiquidity: EXPIRED");
        require(liquidity == 0, "PoolLiquidity: LIQUIDITY_ALREADY_PROVIDED");

        TransferHelper.safeApprove(tokenA, router, amountA);
        TransferHelper.safeApprove(tokenB, router, amountB);

        uint256 depositedLiquidity;
        (, , depositedLiquidity) = IDXswapRouter(router).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            amountA,
            amountB,
            address(this),
            block.timestamp
        );
        TransferHelper.safeApprove(tokenA, router, 0);
        TransferHelper.safeApprove(tokenB, router, 0);
        liquidity = depositedLiquidity;
    }
}
