//SPDX-License-Identifier: Unlicense
/**
 * Created on 2021-01-10 09:36
 * @summary:
 * @author: phuong
 */

pragma solidity 0.8.4;

/**
 * @title
 */
interface INFTManager {
  function discountedMint(address _to, string memory _tokenURI) external;
}
