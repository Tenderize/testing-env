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
import "./Token/ITenderToken.sol";


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