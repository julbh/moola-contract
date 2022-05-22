//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IPancakePair.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Randomizer is Ownable, VRFConsumerBase {
  using SafeMath for uint256;
  using SafeMath for uint128;
  using SafeMath for uint64;

  uint256 internal salt;

  EnumerableSet.UintSet internal seedArray;
  uint256 internal seedIndex;
  uint256 size;

  bytes32 internal keyHash;
  uint256 internal fee;

  address internal NFTCore;

  uint256 public randomResult;

  address pancakeAddress = 0xF855E52ecc8b3b795Ac289f85F6Fd7A99883492b; //TESTNET USDT <> BNB

  //USDT <> BNB

  IPancakePair internal pancakePair = IPancakePair(pancakeAddress);

  constructor()
    VRFConsumerBase(
      0xa555fC018435bef5A13C6c6870a9d4C11DEC329C,
      0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
    )
  {
    salt = 19041998;
    keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
    fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
  }

  /**
   * Requests randomness
   */
  function getRandomNumber() public returns (bytes32 requestId) {
    require(
      LINK.balanceOf(address(this)) >= fee,
      "Not enough LINK - fill contract with faucet"
    );
    return requestRandomness(keyHash, fee);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    randomResult = randomness;
    delete seedArray;
    for (uint256 i = 0; i < size; i++) {
      EnumerableSet.add(
        seedArray,
        uint256(keccak256(abi.encodePacked(randomResult, i)))
      );
    }
  }

  function assignCoreNFT(address _coreAddress) external onlyOwner {
    NFTCore = _coreAddress;
  }

  function getRandomNumberAt(uint256 index)
    external
    view
    onlyOwner
    returns (uint256)
  {
    return EnumerableSet.at(seedArray, index);
  }

  function calc() internal view returns (uint256) {
    (uint112 _reserve0, uint112 _reserve1, ) = pancakePair.getReserves();
    return (uint256(1e18).mul(_reserve0).div(_reserve1));
  }

  function rdmz(uint256 _seed) public returns (uint256) {
    require(msg.sender == NFTCore, "Unauthorized caller of NFTCore");
    //uint256 VRFseed = EnumerableSet.at(seedArray, block.timestamp % size);

    uint256 VRFseed = 1;

    // sha3 and now have been deprecated
    //

    //
    salt = salt.mul(uint256(keccak256(abi.encodePacked(_seed, VRFseed))));

    uint256 offset = 1904;
    return
      uint256(
        keccak256(abi.encode(salt.add(block.timestamp), offset, _msgSender()))
      ) % 10000;

    // convert hash to integer
  }

  function setPancakeAddress(address newAddress) external onlyOwner {
    pancakeAddress = newAddress;
    pancakePair = IPancakePair(pancakeAddress);
  }
}
