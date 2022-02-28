pragma solidity ^0.8.0;

import "./ERC20.sol";

contract UsdTetherToken is ERC20 {
  constructor () ERC20 ("Mock USD Tether Token", "mUSDT") {
    _mint(msg.sender, 1000 * 10**18);
  }
}