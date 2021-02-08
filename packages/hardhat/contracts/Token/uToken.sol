pragma solidity ^0.6.2;

import "./VariableSupplyToken.sol";

contract uToken is VariableSupplyToken {
    constructor(string memory _name, string memory _symbol) 
        public 
        VariableSupplyToken(
            string(abi.encodePacked("tender ", _name)),
            string(abi.encodePacked("t", _symbol))
        ) {}
}