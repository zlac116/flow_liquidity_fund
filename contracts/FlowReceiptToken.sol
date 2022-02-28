pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./utils/Ownable.sol";

contract FlowReceiptToken is ERC20, Ownable {

  constructor () ERC20 ("Flow Receipt Token", "FRT") {}

  function mint(address to, uint amount) onlyOwner() external {
    _mint(to, amount);
  }

  function burn(address from, uint amount) onlyOwner() external {
    _burn(from, amount);
  }
}