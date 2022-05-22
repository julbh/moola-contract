//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRandomizer {
  function rdmz(uint256 _seed) external returns (uint256);
}
