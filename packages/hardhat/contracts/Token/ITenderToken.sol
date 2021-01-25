pragma solidity ^0.6.2;

import "./INamedToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITenderToken is INamedToken, IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
    function burn(uint256 _amount) external;
}