//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Erc20Token {
  function transfer(address dst, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

  function balanceOf(address guy) external view returns (uint256);
}

contract PegsDai is ERC20 {
  Erc20Token public dai;

  constructor() ERC20("PegsDai", "PDAI") {
    dai = Erc20Token(0x97cb342Cf2F6EcF48c1285Fb8668f5a4237BF862);
  }

  function daiBalance() public view returns (uint256) {
    return dai.balanceOf(address(this));
  }

  function buy(uint256 amount) public {
    require(amount > 0, "Ivalid amount");
    require(dai.balanceOf(msg.sender) >= amount, "Insufficient DAI");

    dai.transferFrom(msg.sender, address(this), amount);
    _mint(msg.sender, amount);
  }

  function sell(uint256 amount) public {
    require(amount > 0, "Ivalid amount");
    require(this.balanceOf(msg.sender) >= amount, "Insufficient PDAI");
    require(dai.balanceOf(address(this)) >= amount, "Insufficient DAI");

    this.transferFrom(msg.sender, address(this), amount);
    dai.transfer(msg.sender, amount);
  }
}
