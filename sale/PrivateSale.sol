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

contract PrivateSale is
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  INFTManager private manager;
  IERC20 private WETH;

  uint256 public salePrice;
  address internal recipient;

  bool private disabled;

  mapping(address => bool) private whitelist;

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
    recipient = _recipient;
    disabled = false;
  } //

  function disableContract() external onlyOwner {
    disabled = true;
  }

  function setSalePrice(uint256 _price) external onlyOwner {
    salePrice = _price;
  }

  function grantWhitelist(address[] calldata _whitelistAddresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
      whitelist[_whitelistAddresses[i]] = true;
    }
  }

  function mint(string memory _tokenURI) external payable nonReentrant {
    require(!disabled, "DISABLED");
    require(whitelist[_msgSender()], "NOT_WHITELIST");
    whitelist[_msgSender()] = false;
    payToAddress(salePrice);
    manager.discountedMint(_msgSender(), _tokenURI);
  }
}
