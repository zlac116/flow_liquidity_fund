pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DaiToken is ERC20 {
  constructor () ERC20 ("Mock DAI Token", "mDAI") {
    _mint(msg.sender, 1000 * 10**18);
  }
}