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


    // helpers REMOVE later
    // uint256 public outstanding;
    // uint256 public tenderSupply;
    // uint256 public sp;  


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
        underlyingToken.approve(address(pool), MAX);
        tenderToken.approve(address(pool), MAX);
        }



    // function h_sp_calc() public {
    //         if (tenderSupply ==  0) { 
    //         sp = 1e18; 
    //         } else {
    //     sp = outstanding.mul(1e18).div(tenderSupply);
    // }
    // }

    // function whatIsSharePrice() public returns (uint256) {
    //     return 1e18;
    // }

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
                    }
                    return true;
                    // subtracts user's debt from amount and continues to next user
                } else { 
                    _amount -= users[i].owed;
                    owedTotal -= users[i].owed; // need to transfer all owed funds now to user
                    users[i].owed = 0;
                    nuMcreditors -= 1;
                
                    
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

    function mintTender(uint256 _amount) public {
        tenderToken.mint(msg.sender, _amount);
    }

    // calculates how much underlying tokens is one tendertoken worth
    function sharePrice() public view returns (uint256) {
        uint256 tenderSupplyc = tenderToken.totalSupply().sub(mintedForPool);
        uint256 outstandingc = underlyingToken.balanceOf(address(this)).add(underlyingToken.balanceOf(address(staker)));
        if (tenderSupplyc ==  0) { 
            // sp = 1e18;
            return 1e18; 
            } 
        //sp = outstanding.mul(1e18).div(tenderSupply);
        return outstandingc.mul(1e18).div(tenderSupplyc);
                    // uint256 result = 0;
        // return result;

        
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
        // amount owed to the user -5% fee
        uint256 owed = _amount.mul(sharePrice()).div(1e18).mul(95).div(100);

        // checks if manager has enough funds
        require(underlyingToken.balanceOf(address(this)) >= owed, "NOT_ENOUGH_FUNDS");
        
        // transferFrom tenderToken
        require(tenderToken.transferFrom(msg.sender, address(this), _amount), "ERR_TENDER_TRANSFERFROM");

        // transfer underlying token to user
        underlyingToken.transfer(msg.sender, owed);
    }

    uint256[] owedFunds;

    // memory arrays CANNOT be dynamic 
    uint[] myArray; // crud, create, read, update, delete




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


        



        //         // swap with pool
        // if(isPoolActivated){
        //     (uint256 out) = pool.tenderToToken(_amount);

        //     // send underlying
        //     require(underlyingToken.transfer(msg.sender, out));
        // } else if(underlyingToken.balanceOf(address(this)) >= owed) {
        //     underlyingToken.trasfer(msg.sender, owed)

        // emit Withdraw(msg.sender, _amount, out);


    

    // function _swapInUnderlying(uint256 _tokens) public virtual  returns(bool) {
    //     require(underlyingToken.transferFrom(msg.sender, address(this), _amount), "ERR_TENDER_TRANSFERFROM");
    //     (uint256 outTender) = pool.tokenToEth(_tokens);
    //     tenderToken.transfer(msg.sender, outTender);
    //     return true;
    // }

}