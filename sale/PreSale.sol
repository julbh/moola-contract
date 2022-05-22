//SPDX-License-Identifier: Unlicense

/**
 * Created on 2021-10-04 11:17
 * @summary:
 * @author: phuong
 */
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/INFTManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PreSale is
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  INFTManager private manager;
  IERC20 private WETH;

  uint256 public salePrice;
  address internal recipient;
  uint256 internal limit;

  bool private disabled;

  function payToAddress(uint256 _value) internal {
    WETH.transferFrom(_msgSender(), recipient, _value);
  }

  function initialize(
    address _nftManagerAddress,
    address _wethToken,
    address _recipient,
    uint256 _salePrice
  ) external initializer {
    __Ownable_init();
    manager = INFTManager(_nftManagerAddress);
    WETH = IERC20(_wethToken);
    salePrice = _salePrice;
    limit = 700;
    recipient = _recipient;
    disabled = false;
  } //

  function disableContract() external onlyOwner {
    disabled = true;
  }

  function setSalePrice(uint256 _price) external onlyOwner {
    salePrice = _price;
  }

  function setLimit(uint256 _limit) external onlyOwner {
    limit = _limit;
  }

  function mint(string memory _tokenURI) external payable nonReentrant {
    require(!disabled, "DISABLED");
    require(limit > 0, "ENDED");
    limit = limit - 1;
    payToAddress(salePrice);
    manager.discountedMint(_msgSender(), _tokenURI);
  }
}
