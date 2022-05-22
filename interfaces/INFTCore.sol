//SPDX-License-Identifier: Unlicense
/**
 * Created on 2021-01-10 09:36
 * @summary:
 * @author: phuong
 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 */
interface INFTCore is IERC721EnumerableUpgradeable {
  function mintNFT(address _recipient, string memory _tokenURI)
    external
    returns (uint256);

  function setTokenName(uint256 _tokenId, string memory _tokenName) external;

  function setTokenQuote(uint256 _tokenId, string memory _tokenQuote) external;

  /*╔══════════════════════════════╗
      ║            GETTERS           ║
      ╚══════════════════════════════╝*/

  function getTokenName(uint256 _tokenId) external view returns (string memory);

  function getTokenQuote(uint256 _tokenId)
    external
    view
    returns (string memory);
}
