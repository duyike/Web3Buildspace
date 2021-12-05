// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
  struct Wave {
    address waver;
    uint256 timestamp;
    string message;
  }

  event NewWave(address indexed from, uint256 timestamp, string message);

  uint256 totalWaves;
  Wave[] waves;
  uint256 private seed;
  mapping(address => uint256) lastWavedAt;

  constructor() payable {
    console.log("i'am wavePortal");
    seed = (block.difficulty + block.timestamp) % 100;
  }

  function wave(string memory _message) public {
    require(lastWavedAt[msg.sender] + 15 minutes < block.timestamp, "Wait 15m");

    totalWaves += 1;
    waves.push(Wave(msg.sender, block.timestamp, _message));
    emit NewWave(msg.sender, block.timestamp, _message);
    console.log("%s has waved!", msg.sender);

    lastWavedAt[msg.sender] = block.timestamp;

    seed = (block.difficulty + block.timestamp + seed) % 100;
    if (seed >= 50) {
      console.log("%s won!", msg.sender);

      uint256 prizeAmount = 0.0001 ether;
      require(
        prizeAmount <= address(this).balance,
        "Trying to withdraw more money than the contract has."
      );
      (bool success, ) = msg.sender.call{ value: prizeAmount }("");
      require(success, "Failed to withdraw money from contract.");
    }
  }

  function getAllWaves() public view returns (Wave[] memory) {
    return waves;
  }

  function getTotalWaves() public view returns (uint256) {
    console.log("we have %d total waves!", totalWaves);
    return totalWaves;
  }
}
