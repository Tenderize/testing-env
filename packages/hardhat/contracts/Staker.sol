pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

// libraries
import "@openzeppelin/contracts/math/SafeMath.sol";

// // // local imports 
// // import "./Proxy/ProxyTarget.sol";
import "./Token/TenderToken.sol";
import "./DEX.sol";
import "./Manager.sol";
import "./Token/ITenderToken.sol";

// // external imports
// import "@openzeppelin/contracts/access/Ownable.sol";

// // interfaces 
// import "./IStaker.sol";
import "./Token/ITenderToken.sol";
// import "./Swap/IBPool.sol";
// import "./Swap/IOneInch.sol";
// import "./Swap/IWETH.sol";

// import "./Balancer/contracts/test/BNum.sol";

// // WETH Address 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

contract Staker {
    using SafeMath for uint256;

    uint256 internal constant ONE = 1e18;
    uint256 internal constant MAX = 2**256-1;
    uint256 internal constant MIN = 1; 
    uint256 internal constant liquidityPercentage = 1e17;

    // Tokens
    // Underlying asset
    ITenderToken public underlyingToken;
    // Derivative
    ITenderToken public tenderToken;
    Manager public manager;

    // Swap
    DEX public pool; 


    // // Swap
    // Balancer public balancer; 
    // IOneInch oneInch;
    // IWETH weth;

    // staking
    uint256 public stakedUnderlying;
    uint256 public stakingRewards;

    constructor (address _underlyingToken_addr, address _tenderToken_addr, address _pool_addr) public {
        underlyingToken = ITenderToken(_underlyingToken_addr);
        tenderToken = ITenderToken(_tenderToken_addr);
        pool = DEX(_pool_addr);
            }
    function initManager(address _manager_addr) public {
        manager = Manager(_manager_addr);
        underlyingToken.approve(address(manager), MAX);
        tenderToken.approve(address(manager), MAX);

    }    



    // TODO: WETH and oneInch can be constants 
    // Balancer Pool needs to be created in constructor because we can not add liquidity for both tokens otherwise
    // Will have to approve _token before calling init and in init call _token.transferFrom then mint the same amount of tenderToken
    // And add both to the pool
    // function init(IERC20 _token, ITenderToken _tenderToken, Balancer memory _balancer, IOneInch _oneInch, IWETH _weth) public virtual {
    //     token = _token;
    //     tenderToken = _tenderToken;
    //     balancer = _balancer;
    //     oneInch = _oneInch;
    //     weth = _weth;
    // }

    function _stake(uint256 _stakeAmount) public returns (bool) {
        stakedUnderlying += _stakeAmount;
        require(underlyingToken.transferFrom(msg.sender, address(this), _stakeAmount), "ERR_TOKEN_TANSFERFROM");
        return true;
    }

    function _unstake(uint256 _unstakeAmount) public virtual returns (bool) {
        stakedUnderlying -= _unstakeAmount;
        return true;
    }
    function _stakerBalance() public virtual view returns (uint256) {
        uint256 balance = stakedUnderlying + stakingRewards;
        return balance;
    }     
    
    function _runRewards(uint256 _rewards) public {
        underlyingToken.mint(address(this), _rewards);
        stakingRewards += _rewards;
    }      

}