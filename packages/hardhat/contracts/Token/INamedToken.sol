pragma solidity ^0.6.2;

interface INamedToken {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
}