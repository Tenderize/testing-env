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

  constructor(address token_addr, address tender_addr) public {
    token = IERC20(token_addr);
    tender = IERC20(tender_addr);
  }

function init(uint256 tokens, uint256 tenders) public returns (uint256) {
  require(totalLiquidity==0,"DEX:init - already has liquidity");
  totalLiquidity = tokens;
  liquidity[msg.sender] = totalLiquidity;
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

  function priceStable(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  return numerator / denominator;
  }


function getSpotPrice() public view returns (uint256) {
  uint256 numerator = token.balanceOf(address(this));
  uint256 denominator = tender.balanceOf(address(this));
  if(denominator == 0) return 1e18;
  return numerator.mul(1e18).div(denominator);
}

// TODO this fx should fail if pools has not enough tender to send back but it doesnt!!!???
function tenderToToken(uint256 tenders) public returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 norm_tenders = tenders.mul(1e18).div(currentSharePrice);
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this)).mul(1e18).div(currentSharePrice);
  uint256 token_bought = priceStable(norm_tenders, tender_reserve, token_reserve);
  require(token.transfer(msg.sender, token_bought));
  require(tender.transferFrom(msg.sender, address(this), tenders));
  return token_bought;
}
function tokenToTender(uint256 tokens) public returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this)).mul(1e18).div(currentSharePrice);
  uint256 tender_bought = priceStable(tokens, token_reserve, tender_reserve);
  tender.transfer(msg.sender, tender_bought);
  require(token.transferFrom(msg.sender, address(this), tokens));
  return tender_bought;
}

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
