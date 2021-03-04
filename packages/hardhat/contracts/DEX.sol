pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Manager.sol";

contract DEX {

  using SafeMath for uint256;
  IERC20 token;
  IERC20 tender;

  Manager public manager;

  uint256 public totalLiquidity;
  mapping (address => uint256) public liquidity;

  uint256 public invariant;
  uint256 public sub;

  constructor(address token_addr, address tender_addr) public {
    token = IERC20(token_addr);
    tender = IERC20(tender_addr);
  }

function init(uint256 tokens, uint256 tenders, uint256 _invariant) public returns (uint256) {
  require(totalLiquidity==0,"DEX:init - already has liquidity");
  totalLiquidity = tokens;
  liquidity[msg.sender] = totalLiquidity;
  invariant = _invariant; // tokens.mul(tenders).div(1e18);
  require(token.transferFrom(msg.sender, address(this), tokens));
  require(tender.transferFrom(msg.sender, address(this), tenders));
  return totalLiquidity;
  }

    function initManager(address _manager_addr) public {
        manager = Manager(_manager_addr);
        // underlyingToken.approve(address(manager), MAX);
        // tenderToken.approve(address(manager), MAX);

    }    

// function fundPool(uint256 tokens) public returns (uint256) {
//   require(totalLiquidity=!0,"DEX not initiated");
//   totalLiquidity += tokens;
//   liquidity[msg.sender] = totalLiquidity;
//   require(token.transferFrom(msg.sender, address(this), tokens));
//   require(tender.transferFrom(msg.sender, address(this), tokens));
//   return totalLiquidity;
//   }

function tokenBalance() public view returns (uint256) {
  return token.balanceOf(address(this));
}

function tenderBalance() public view returns (uint256) {
  return tender.balanceOf(address(this));
}

function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  return numerator / denominator;
  }

function amountTokenOut(uint256 tender_amount, uint256 tender_reserve, uint256 token_reserve) public view returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 tender_amount_with_fee = tender_amount.mul(997).mul(1e18).div(currentSharePrice);
  uint256 norm_tender_reserve = tender_reserve.mul(1e18).div(currentSharePrice);
  uint256 numerator = tender_amount_with_fee.mul(token_reserve);
  uint256 denominator = norm_tender_reserve.mul(1000).add(tender_amount_with_fee);
  return numerator / denominator;
  }

  function amountTenderOut(uint256 token_amount, uint256 token_reserve, uint256 tender_reserve) public view returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 token_amount_with_fee = token_amount.mul(997);
  uint256 norm_tender_reserve = tender_reserve.mul(1e18).div(currentSharePrice);
  uint256 numerator = token_amount_with_fee.mul(norm_tender_reserve);
  uint256 denominator = token_reserve.mul(1000).add(token_amount_with_fee);
  return numerator / denominator;
  }

  function priceScaffold(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 numerator = input_amount.mul(output_reserve);
  uint256 denominator = input_reserve.add(input_amount);
  uint256 result = numerator / denominator;
  return result.mul(997).div(1000);
  }

  function priceConstProdInv(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public returns (uint256) {
  uint256 main = output_reserve;
  uint256 subtractor = invariant.mul(1e18).div(input_reserve.add(input_amount));
  uint256 result = main.sub(subtractor);
  return result.mul(997).div(1000);
  }

function priceStableSwap(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public returns(uint256) {


    uint256 x = input_reserve + input_amount;
    uint256 y = 100; // get_y(x);

    uint256 dy = output_reserve - y - 1; // # -1 just in case there were some rounding errors


    // here only tokens are transfered

    return dy.mul(997).div(1000);

}


function get_y(uint256 in_A_plus_B) public returns(uint256) {
    // xp_ == coin balances
    uint256 N_COINS = 2;
    uint256 A_PRECISION = 100;

    uint256 A = 20;
    uint256 D = 20;
    uint256 Ann = A * 2;
    uint256 c = D;
    uint256 S = 0;
    uint256 y_prev = 0;

    uint256 _x = 0;
    uint256 i = 0;

    S += _x;
    c = c * D / (_x * N_COINS);
    c = c * D * A_PRECISION / (Ann * N_COINS);
    uint256 b = S + D * A_PRECISION / Ann;
    uint256 y = D;

    uint x = in_A_plus_B;
    uint _i = i;
    _x = x;
    
    
    for (_i = 0; _i < 255; _i++){
        y_prev = y;
        y = (y * y + c) / (2 * y + b - D); 
        if(y > y_prev){
            if(y - y_prev <= 1) {
                return y;
            }} else {
                if(y_prev - y <= 1) {
                    return y; } 
        } 
        }
    
}



  function priceStableMul(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 numerator = input_amount.mul(output_reserve.mul(20));
  uint256 denominator = input_reserve.mul(20).add(input_amount);
  uint256 result = numerator / denominator;
  return result.mul(997).div(1000);
  }

  function priceStableOld(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  return numerator / denominator;
  }


function getSpotPrice() public view returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 numerator = token.balanceOf(address(this));
  uint256 denominator = tender.balanceOf(address(this)).mul(1e18).div(currentSharePrice);
  if(denominator == 0) return 1e18;
  return numerator.mul(1e18).div(denominator);
}

// TODO this fx should fail if pools has not enough tender to send back but it doesnt!!!???
function tenderToToken(uint256 tenders) public returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this));
  uint256 token_bought = priceConstProdInv(tenders, tender_reserve, token_reserve);
  uint256 norm_tok_bought = token_bought.mul(currentSharePrice).div(1e18);
  require(token.transfer(msg.sender, norm_tok_bought));
  require(tender.transferFrom(msg.sender, address(this), tenders));
  return norm_tok_bought;
}
function tokenToTender(uint256 tokens) public returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this));
  uint256 tender_bought = priceConstProdInv(tokens, token_reserve, tender_reserve);
  uint256 norm_tender_bought = tender_bought.mul(1e18).div(currentSharePrice);
  tender.transfer(msg.sender, norm_tender_bought);
  require(token.transferFrom(msg.sender, address(this), tokens));
  return norm_tender_bought;
}

// function tenderToToken(uint256 tenders) public returns (uint256) {
//   uint256 currentSharePrice = manager.sharePrice();
//   uint256 token_reserve = token.balanceOf(address(this));
//   uint256 tender_reserve = tender.balanceOf(address(this));
//   uint256 token_bought = priceStable(tenders, tender_reserve, token_reserve);
//   uint256 norm_tok_bought = token_bought.mul(currentSharePrice).div(1e18);
//   require(token.transfer(msg.sender, norm_tok_bought));
//   require(tender.transferFrom(msg.sender, address(this), tenders));
//   return norm_tok_bought;
// }
// function tokenToTender(uint256 tokens) public returns (uint256) {
//   uint256 currentSharePrice = manager.sharePrice();
//   uint256 token_reserve = token.balanceOf(address(this));
//   uint256 tender_reserve = tender.balanceOf(address(this));
//   uint256 tender_bought = priceStable(tokens, token_reserve, tender_reserve);
//   uint256 norm_tender_bought = tender_bought.mul(1e18).div(currentSharePrice);
//   tender.transfer(msg.sender, norm_tender_bought);
//   require(token.transferFrom(msg.sender, address(this), tokens));
//   return norm_tender_bought;
// }

// function deposit(uint256 _amount) public payable returns (uint256) {
//   uint256 _amount;
//   uint256 tender_reserve = tender.balanceOf(address(this));
//   uint256 token_reserve = token.balanceOf(address(this));
//   uint256 token_amount = (_amount.mul(token_reserve) / eth_reserve).add(1);
//   uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;
//   liquidity[msg.sender] = liquidity[msg.sender].add(liquidity_minted);
//   totalLiquidity = totalLiquidity.add(liquidity_minted);
//   require(token.transferFrom(msg.sender, address(this), token_amount));
//   return liquidity_minted;
// }
// function withdraw(uint256 amount) public returns (uint256, uint256) {
//   uint256 token_reserve = token.balanceOf(address(this));
//   uint256 eth_amount = amount.mul(address(this).balance) / totalLiquidity;
//   uint256 token_amount = amount.mul(token_reserve) / totalLiquidity;
//   liquidity[msg.sender] = liquidity[msg.sender].sub(eth_amount);
//   totalLiquidity = totalLiquidity.sub(eth_amount);
//   msg.sender.transfer(eth_amount);
//   require(token.transfer(msg.sender, token_amount));
//   return (eth_amount, token_amount);
// }

}
