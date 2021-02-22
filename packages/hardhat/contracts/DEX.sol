pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Manager.sol";

contract DEX {

  using SafeMath for uint256;
  IERC20 token;
  IERC20 tender;

  Manager public manager;


  constructor(address token_addr, address tender_addr) public {
    token = IERC20(token_addr);
    tender = IERC20(tender_addr);
  }

  // initializes pool
  function init(uint256 tokens, uint256 tenders) public {


  require(token.transferFrom(msg.sender, address(this), tokens));
  require(tender.transferFrom(msg.sender, address(this), tenders));

  }


  function initManager(address _manager_addr) public {
      manager = Manager(_manager_addr);

  }    


  // calculates how much tokens to send out when tokens are sent in
  function priceStable(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 numerator = input_amount.mul(output_reserve);
  uint256 denominator = input_reserve.add(input_amount);
  uint256 result = numerator / denominator;
  return result.mul(997).div(1000);
  }


// this returns price of the 1 tenderToken in pool (normalized by shareprice)
function getSpotPrice() public view returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 numerator = token.balanceOf(address(this));
  uint256 denominator = tender.balanceOf(address(this)).mul(1e18).div(currentSharePrice);
  if(denominator == 0) return 1e18;
  return numerator.mul(1e18).div(denominator);
}

// this is called by manager to exchange funds
function tenderToToken(uint256 tenders) public returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this));
  uint256 token_bought = priceStable(tenders, tender_reserve, token_reserve);
  uint256 norm_tok_bought = token_bought.mul(currentSharePrice).div(1e18);
  require(token.transfer(msg.sender, norm_tok_bought));
  require(tender.transferFrom(msg.sender, address(this), tenders));
  return norm_tok_bought;
}

// this is called by manager to exchange funds
function tokenToTender(uint256 tokens) public returns (uint256) {
  uint256 currentSharePrice = manager.sharePrice();
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tender_reserve = tender.balanceOf(address(this));
  uint256 tender_bought = priceStable(tokens, token_reserve, tender_reserve);
  uint256 norm_tender_bought = tender_bought.mul(1e18).div(currentSharePrice);
  tender.transfer(msg.sender, norm_tender_bought);
  require(token.transferFrom(msg.sender, address(this), tokens));
  return norm_tender_bought;
}


}
