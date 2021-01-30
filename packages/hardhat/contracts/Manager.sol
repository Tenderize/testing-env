pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// libraries
import "@openzeppelin/contracts/math/SafeMath.sol";

// local imports 
// import "./Proxy/ProxyTarget.sol";
import "./Token/TenderToken.sol";
import "./DEX.sol";
import "./Staker.sol";
import "./Token/ITenderToken.sol";

// external imports
// import "@openzeppelin/contracts/access/Ownable.sol";

// interfaces 

// import "./Swap/IBPool.sol";
// import "./Swap/IOneInch.sol";
// import "./Swap/IWETH.sol";

// import "./Balancer/contracts/test/BNum.sol";

// WETH Address 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

contract Manager {
    using SafeMath for uint256;

   uint256 internal constant ONE = 1e18;
    uint256 internal constant MAX = 2**256-1;
    uint256 internal constant MIN = 1; 
    uint256 internal constant liquidityPercentage = 1e17; 

   
    // Tokens
    // Underlying asset
    IERC20 public underlyingToken;
    // Derivative
    ITenderToken public tenderToken;
    Staker public staker;

    // Swap
    DEX public pool; 

    uint256 public mintedForPool;

    // helpers REMOVE later
    uint256 public outstanding;
    uint256 public tenderSupply;
    uint256 public sp;  


    // TODO: WETH and oneInch can be constants 
    // Balancer Pool needs to be created in constructor because we can not add liquidity for both tokens otherwise
    // Will have to approve _token before calling init and in init call _token.transferFrom then mint the same amount of tenderToken
    // And add both to the pool
    constructor (address _underlyingToken_addr, address _tenderToken_addr, address _pool_addr, address _staker_addr) public {
        underlyingToken = IERC20(_underlyingToken_addr);
        tenderToken = ITenderToken(_tenderToken_addr);
        pool = DEX(_pool_addr);
        staker = Staker(_staker_addr);
        underlyingToken.approve(address(staker), MAX);
        // underlyingToken.approve(address(pool), MAX);
        // tenderToken.approve(address(pool), MAX);
        }

    function sharePrice() public returns (uint256) {
        tenderSupply = tenderToken.totalSupply().sub(mintedForPool);
        outstanding = underlyingToken.balanceOf(address(this)).add(underlyingToken.balanceOf(address(staker))).add(underlyingToken.balanceOf(address(pool)));
        if (tenderSupply ==  0) { 
            return 0; 
            } else {
                return outstanding.mul(1e18).div(tenderSupply);
            }

        
    }

    function h_sp_calc() public {
        sp = outstanding.mul(1e18).div(tenderSupply);
    }

    function whatIsSharePrice() public returns (uint256) {
        return sharePrice();
    }

    function initPool(uint256 _initial_liquidity) public {
        pool.init(_initial_liquidity);
        mintedForPool += _initial_liquidity;

    }

    function mintTender(uint256 _amount) public {
        tenderToken.mint(msg.sender, _amount);
    }
    function deposit(uint256 _amount) public  {
        // Calculate share price
        uint256 currentSharePrice = sharePrice();
        uint256 shares;

        if(currentSharePrice == 0) {
            shares = _amount;
        } else {_amount.mul(1e18).div(currentSharePrice);
            }

        // Mint tenderToken
        tenderToken.mint(msg.sender, shares);

         // Transfer LPT to Staker
        require(underlyingToken.transferFrom(msg.sender, address(this), _amount), "ERR_TOKEN_TANSFERFROM");

        // Stake deposited amount
        staker._stake(_amount);

        // Check if we need to do arbitrage if spotprice is at least 10% below shareprice
        // TODO: use proper maths (MathUtils)
        // address _token = address(underlyingToken);
        // address _tenderToken = address(tenderToken);
        // uint256 poolPrice = pool.getSpotPrice();

        // if pool price is more than 10% off the peg trade into pool
        // if (poolPrice.mul(110).div(100) < currentSharePrice) {
        //     pool.tokenToTender(_amount);

        //     // uint256 tokenIn = balancerCalcInGivenPrice(_token, _tenderToken, sharePrice, spotPrice);
        //     // if (tokenIn > _amount) {
        //     //     tokenIn = _amount;
        //     // }
        //     // token.approve(address(balancer.pool), tokenIn);
        //     // (uint256 out,) = balancer.pool.swapExactAmountIn(_token, tokenIn, _tenderToken, MIN, MAX);
        //     // // burn the derivative amount we bought up 
        //     // tenderToken.burn(out);
        //     // _amount  = _amount.sub(tokenIn);
        // } 
        // else {
        //     staker._stake(_amount);

        // }

        // TODO: require proper minimum boundary
        // if (_amount <= 1) { return; }




    }

    function withdraw(uint256 _amount) public virtual  {
        // uint256 owed = _amount.mul(sharePrice()).div(1e18);

        // transferFrom tenderToken
        require(tenderToken.transferFrom(msg.sender, address(this), _amount), "ERR_TENDER_TRANSFERFROM");
        
        // swap with balancer
                
        (uint256 out) = pool.tenderToToken(_amount);

        // send underlying
        require(underlyingToken.transfer(msg.sender, out));

        // emit Withdraw(msg.sender, _amount, out);


    }

    // function _swapInUnderlying(uint256 _tokens) public virtual  returns(bool) {
    //     require(underlyingToken.transferFrom(msg.sender, address(this), _amount), "ERR_TENDER_TRANSFERFROM");
    //     (uint256 outTender) = pool.tokenToEth(_tokens);
    //     tenderToken.transfer(msg.sender, outTender);
    //     return true;
    // }

}