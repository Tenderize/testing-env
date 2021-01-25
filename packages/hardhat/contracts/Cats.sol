pragma solidity ^0.6.6;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Cats is ERC20 {
  constructor() ERC20("Cats","🐈") public {
      _mint(msg.sender,50000*10**18);
  }
}