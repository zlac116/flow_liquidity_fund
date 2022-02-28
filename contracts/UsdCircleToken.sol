pragma solidity ^0.8.0;

import "./ERC20.sol";

contract UsdCircleToken is ERC20 {
  constructor () ERC20 ("Mock USD Circle Token", "mUSDC") {
    _mint(msg.sender, 1000 * 10**18);
  }
}