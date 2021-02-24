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



contract Manager {
    using SafeMath for uint256;

    uint256 internal constant ONE = 1e18;
    uint256 internal constant MAX = 2**256-1;
    uint256 internal constant MIN = 1; 


   
    // Tokens
    // Underlying asset
    IERC20 public underlyingToken;
    // Derivative
    ITenderToken public tenderToken;
    Staker public staker;

    // pool
    DEX public pool; 

    // we need to keep track of this to calculate share price correctly
    uint256 public mintedForPool;



    // creditors count + total amount owed
    uint256 public nuMcreditors;
    uint256 public owedTotal;


    struct User {
    address u_address;       
    uint256 owed;
    }  

    // array of creditors 
    User[] public users;
    




    



    // check if AMM pool is initiated
    bool public isPoolActivated;


    uint256 liquidityRatioForReserve = 1e17;
    bool isReserveActive = true; 



    constructor (address _underlyingToken_addr, address _tenderToken_addr, address _pool_addr, address _staker_addr) public {
        underlyingToken = IERC20(_underlyingToken_addr);
        tenderToken = ITenderToken(_tenderToken_addr);
        pool = DEX(_pool_addr);
        staker = Staker(_staker_addr);
        underlyingToken.approve(address(staker), MAX);
        underlyingToken.approve(address(pool), MAX);
        tenderToken.approve(address(pool), MAX);
    }

    // add a new credit to array
    function addCreditor(address _address, uint256 _amount) public returns (bool) {
        users.push(User(_address, _amount));
        nuMcreditors ++;
        owedTotal += _amount;
        return true;
    }  
    

    // pays out whole input amount to creditors, in order from first, 
    // TODO we need to pay out sol, based on the changes in arrays
    // ?? maybe pay out max 3 creditrs??? => otherwise many calls, high costs for who calls the function 
    function payCreditors(uint256 _amount) public returns (bool) {
        require(owedTotal >= _amount, "amount greater than owed");
        for (uint i = 0; i<users.length; i++){ // looping always starts at 0, we could add counter so it start at last position, not sure if it is wanted
            // checks arrays, skips those with empty values
            if(users[i].owed != 0) {
                // check if all amount goes to the next creditor; sends him this ammount
                if(users[i].owed >= _amount) {
                    users[i].owed -= _amount; // need to transfer _amount of funds now to user
                    owedTotal -= _amount;
                    // removes the user from creditors if his balance is 0
                    if(users[i].owed == 0){
                        nuMcreditors -= 1;
                        // cleans whole array when all debts are paid
                        if(owedTotal == 0){
                            delete users;
                        }
                    }
                    return true;
                    // subtracts user's debt from amount and continues to next user
                } else { 
                    _amount -= users[i].owed;
                    owedTotal -= users[i].owed; // need to transfer all owed funds now to user
                    users[i].owed = 0;
                    nuMcreditors -= 1;
                        // cleans whole array when all debts are paid
                        if(owedTotal == 0){
                            delete users;
                        }
                
                    
                }
                    
                }
                 
            }

            
            
    }


    // controls if we use reserve or AMM
    function setReserveActive(bool _setState) public returns(bool) {
        isReserveActive = _setState;
        return isReserveActive;
    }


    // initializes pool => phase 2
    function initPool(uint256 _initial_liquidity) public {

        //check if pool isn't active
        require(isPoolActivated == false, "POOL_ALREADY_ACTIVE");

        
        // // Calculate share price + num of shares to mint
        // uint256 currentSharePrice = sharePrice();
        // uint256 shares;
        // if(currentSharePrice == 1e18) {
        //     shares = _initial_liquidity;
        //     } 
        // shares = _initial_liquidity.mul(1e18).div(currentSharePrice);
        
        // Transfer underlying token to get initial lq for pool
        require(underlyingToken.transferFrom(msg.sender, address(this), _initial_liquidity), "ERR_TOKEN_TANSFERFROM");


        // Mint tenderToken for pool + discount these tokens
        require(tenderToken.mint(address(this), _initial_liquidity), "ERR_TOKEN_NOT_MINTED");
        mintedForPool += _initial_liquidity;

        pool.init(_initial_liquidity, _initial_liquidity);

        isPoolActivated = true;
        

    }


    // calculates how much underlying tokens is one tendertoken worth
    function sharePrice() public view returns (uint256) {
        uint256 tenderSupplyc = tenderToken.totalSupply().sub(mintedForPool);
        uint256 outstandingc = underlyingToken.balanceOf(address(this)).add(underlyingToken.balanceOf(address(staker)));
        if (tenderSupplyc ==  0) { 
            
            return 1e18; 
            } 
        
        return outstandingc.mul(1e18).div(tenderSupplyc);
       

        
    }

    function deposit(uint256 _amount) public  {
        // Calculate share price
        uint256 currentSharePrice = sharePrice();
        uint256 shares;
        uint256 _amount_staked;

        if(currentSharePrice == 1e18) {
            shares = _amount;
        } 
        shares = _amount.mul(1e18).div(currentSharePrice);

        //splits funds into reserve and staker 
        if(isReserveActive) {
            uint256 _amount_reserved = _amount.mul(liquidityRatioForReserve).div(1e18);
            _amount_staked = _amount.sub(_amount_reserved);

        } else {
             _amount_staked = _amount; 

        } 
      // Mint tenderToken
        require(tenderToken.mint(msg.sender, shares), "ERR_TOKEN_NOT_MINTED");

         // Transfer LPT to Manager
        require(underlyingToken.transferFrom(msg.sender, address(this), _amount), "ERR_TOKEN_TANSFERFROM");

        // Stake deposited amount
        staker._stake(_amount_staked);


    }

    function withdraw(uint256 _amount) public virtual  {
        // amount owed to the user -5% fee
        uint256 owed = _amount.mul(sharePrice()).div(1e18).mul(95).div(100);

        // checks if manager has enough funds
        require(underlyingToken.balanceOf(address(this)) >= owed, "NOT_ENOUGH_FUNDS");
        
        // transferFrom tenderToken
        require(tenderToken.transferFrom(msg.sender, address(this), _amount), "ERR_TENDER_TRANSFERFROM");

        // transfer underlying token to user
        underlyingToken.transfer(msg.sender, owed);
    }


    // get user in line to wait for future deposits 
    function getInLine(uint256 _amount) public returns(bool) {
        // transferFrom tenderToken
        require(tenderToken.transferFrom(msg.sender, address(this), _amount), "ERR_TENDER_TRANSFERFROM");
        uint256 owed = _amount.mul(sharePrice()).div(1e18).mul(95).div(100);

        // checks creditor was added
        bool success;
        success = addCreditor(msg.sender, owed);
        return success;



    }

}