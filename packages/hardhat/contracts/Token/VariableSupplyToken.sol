pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VariableSupplyToken is ERC20, Ownable {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);

    constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {}

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Burns a specific amount of the sender's tokens
     * @param _amount The amount of tokens to be burned
     */
    function burn(uint256 _amount) public onlyOwner {
        _burn(msg.sender, _amount);
        emit Burn(msg.sender, _amount);
    }
}