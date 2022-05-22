//SPDX-License-Identifier: Unlicense
/**
 * Created on 2021-01-10 09:36
 * @summary:
 * @author: phuong
 */
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/INFTCore.sol";

/// @title ERC20MockContract
/// @notice
///
/**
 */
contract Moola is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {
  uint256 internal dailyAllowance;

  uint256 internal cooldown;

  IERC721EnumerableUpgradeable internal moolaNFT;

  mapping(address => bool) internal whitelist;
  mapping(uint256 => uint256) internal nftLastClaimed;

  modifier onlyWhitelist() {
    require(whitelist[msg.sender], "Only whitelist");
    _;
  }

  event dailyDairyClaimed(address receiver, uint256 amount, uint256 time);

  function initialize(string memory name_, string memory symbol_)
    external
    initializer
  {
    __ERC20_init(name_, symbol_);
    __Ownable_init();
    __Pausable_init();

    _mint(msg.sender, 10000000000 * 1e18);
    cooldown = 1 minutes;
  }

  function setWhitelist(address _whitelist) external onlyOwner {
    whitelist[_whitelist] = true;
  }

  function setCooldown(uint256 _cooldown) external onlyOwner {
    cooldown = _cooldown;
  }

  function setDailyAllowance(uint256 _dailyAllowance) external onlyOwner {
    dailyAllowance = _dailyAllowance;
  }

  function setMoolaNFTAddress(address _moola) external onlyOwner {
    moolaNFT = IERC721EnumerableUpgradeable(_moola);
  }

  /// @notice
  ///
  /// @return
  /**
   * :
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  ///
  /// @param to
  /// @param amount
  /// @return
  /**
   * :
   * @param to ??
   * @param amount ??
   */
  function mint(address to, uint256 amount) external onlyWhitelist {
    _mint(to, amount);
  }

  function claimDairy(uint256 _tokenId) external {
    require(moolaNFT.ownerOf(_tokenId) == msg.sender, "UNAUTHORIZED");
    require(
      block.timestamp - nftLastClaimed[_tokenId] >= 1 days,
      "ON COOLDOWN"
    );

    _mint(msg.sender, dailyAllowance);
    nftLastClaimed[_tokenId] = block.timestamp;

    emit dailyDairyClaimed(msg.sender, dailyAllowance, block.timestamp);
  }

  function getLastClaimed(uint256 _tokenId) external view returns (uint256) {
    return nftLastClaimed[_tokenId];
  }
}
