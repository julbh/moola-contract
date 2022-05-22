//SPDX-License-Identifier: Unlicense
/**
 * Created on 2021-01-10 09:36
 * @summary:
 * @author: phuong
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IRandomizer.sol";

contract NFTCore is
  ERC721EnumerableUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using Counters for Counters.Counter;
  using StringsUpgradeable for uint256;
  Counters.Counter private _tokenIds;
  address private managerAddress;
  IERC20 internal dairyERC20;
  IERC20 internal WETH;

  address internal feeRecipient;

  uint256 internal mintPrice;
  uint256 internal namePrice;
  uint256 internal quotePrice;

  mapping(uint256 => string) private _tokenNameList;
  mapping(uint256 => string) private _tokenQuoteList;
  mapping(uint256 => string) private _uniqueNFTData;

  mapping(address => bool) private whitelistAddress;

  uint256 internal circulatingLimit;

  string private defaultURI;

  struct MoolaMetadata {
    string accessory;
    string background;
    string body;
    string eyes;
    string mouth;
    string outfit;
  }

  mapping(uint256 => MoolaMetadata) private _tokenInfo;

  struct BreedingOfferInfo {
    address sender;
    address receiver;
    uint256 senderTokenIds;
    uint256 receiverTokenIds;
    uint256 status;
  }

  Counters.Counter private _offerIdCounter;
  IRandomizer internal randomizer;
  mapping(uint256 => BreedingOfferInfo) private _offerInfos;

  mapping(address => EnumerableSet.UintSet) private _outgoingOrders;
  mapping(address => EnumerableSet.UintSet) private _incomingOrders;

  /*╔══════════════════════════════╗
      ║         CONSTRUCTOR          ║
      ╚══════════════════════════════╝*/

  function initialize(
    string memory name_,
    string memory symbol_,
    address _dairyERC,
    address _wethToken,
    address _feeRecipient
  ) external initializer {
    __ERC721_init(name_, symbol_);
    __Ownable_init();
    __Pausable_init();
    dairyERC20 = IERC20(_dairyERC);
    WETH = IERC20(_wethToken);
    feeRecipient = _feeRecipient;
    circulatingLimit = 9080;
    mintPrice = 7 * 1e16;
    namePrice = 100 * 1e18;
    quotePrice = 200 * 1e18;
  }

  /*╔══════════════════════════════╗
      ║            EVENTS            ║
      ╚══════════════════════════════╝*/

  event TokenNameChanged(uint256 tokenId, string tokenName);

  event TokenQuoteChanged(uint256 tokenId, string tokenQuote);

  event Breeded(uint256 tokenId);

  /*╔══════════════════════════════╗
      ║      ADMIN FUNCTIONS         ║
      ╚══════════════════════════════╝*/

  function setMintPrice(uint256 _newPrice) external onlyOwner {
    mintPrice = _newPrice;
  }

  function setNamePrice(uint256 _newPrice) external onlyOwner {
    namePrice = _newPrice;
  }

  function setQuotePrice(uint256 _newPrice) external onlyOwner {
    quotePrice = _newPrice;
  }

  function setWhitelist(address _whitelist) external onlyOwner {
    whitelistAddress[_whitelist] = true;
  }

  function unsetWhitelist(address _whitelist) external onlyOwner {
    whitelistAddress[_whitelist] = false;
  }

  function setRandomizer(address _randomizer) external onlyOwner {
    randomizer = IRandomizer(_randomizer);
  }

  function setCirculatingLimit(uint256 _limit) external onlyOwner {
    circulatingLimit = _limit;
  }

  function setDefaultURI(string memory _defaultURI) external onlyOwner {
    defaultURI = _defaultURI;
  }

  /**
   * @dev Pay to designated address
   * @param _value Transfer value
   */
  function _payToAddressWETH(uint256 _value) internal {
    WETH.transferFrom(_msgSender(), feeRecipient, _value);
  }

  /**
   * @dev Pay to designated address
   * @param _value Transfer value
   */
  function _payToAddressERC20(uint256 _value) internal {
    dairyERC20.transferFrom(_msgSender(), feeRecipient, _value);
  }

  function updateTokenURI(uint256 _tokenId, string memory _newTokenURI)
    public
    onlyOwner
  {
    _uniqueNFTData[_tokenId] = _newTokenURI;
  }

  function assignInitialMetadata(uint256 _tokenId, string[] memory _metadatas)
    public
    onlyOwner
  {
    _tokenInfo[_tokenId].accessory = _metadatas[0];
    _tokenInfo[_tokenId].background = _metadatas[1];
    _tokenInfo[_tokenId].body = _metadatas[2];
    _tokenInfo[_tokenId].eyes = _metadatas[3];
    _tokenInfo[_tokenId].mouth = _metadatas[4];
    _tokenInfo[_tokenId].outfit = _metadatas[5];
  }

  /*╔══════════════════════════════╗
      ║    INTERNAL FUNCTIONS        ║
      ╚══════════════════════════════╝*/

  function _breed(
    uint256 _parentOne,
    uint256 _parentTwo,
    uint256 _child
  ) internal {
    uint256 _seed = uint256(
      keccak256(abi.encodePacked(_msgSender(), block.timestamp))
    );

    uint256[6] memory _metadatas = [
      uint256(0),
      uint256(0),
      uint256(0),
      uint256(0),
      uint256(0),
      uint256(0)
    ];

    uint256 randomFactor = randomizer.rdmz(_seed);

    for (uint256 i = 0; i < 6; i++) {
      uint256 random = uint256(keccak256(abi.encodePacked(randomFactor, i))) %
        10000;
      _metadatas[i] = random;
    }

    _tokenInfo[_child].accessory = _metadatas[0] > 5000
      ? _tokenInfo[_parentOne].accessory
      : _tokenInfo[_parentTwo].accessory;

    _tokenInfo[_child].background = _metadatas[1] > 5000
      ? _tokenInfo[_parentOne].background
      : _tokenInfo[_parentTwo].background;

    _tokenInfo[_child].body = _metadatas[2] > 5000
      ? _tokenInfo[_parentOne].body
      : _tokenInfo[_parentTwo].body;

    _tokenInfo[_child].eyes = _metadatas[3] > 5000
      ? _tokenInfo[_parentOne].eyes
      : _tokenInfo[_parentTwo].eyes;

    _tokenInfo[_child].mouth = _metadatas[4] > 5000
      ? _tokenInfo[_parentOne].mouth
      : _tokenInfo[_parentTwo].mouth;

    _tokenInfo[_child].outfit = _metadatas[5] > 5000
      ? _tokenInfo[_parentOne].outfit
      : _tokenInfo[_parentTwo].outfit;
  }

  /*╔══════════════════════════════╗
      ║      PUBLIC FUNCTIONS        ║
      ╚══════════════════════════════╝*/

  function internalMint(address _recipient, string memory _tokenURI)
    internal
    returns (uint256)
  {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _mint(_recipient, newItemId);
    _uniqueNFTData[newItemId] = _tokenURI;

    return newItemId;
  }

  /**
   * @dev Mint with no fee. Only whitelist addresses are eligible
   * @param _to Destination address
   */
  function discountedMint(address _to, string memory _tokenURI)
    external
    nonReentrant
  {
    require(whitelistAddress[_msgSender()], "NOT_ELIGIBLE");
    internalMint(_to, _tokenURI);
  }

  /**
   * @dev Standard minting with fees.
   Comes with 3 options, 0 means mint 1x, 1 means mint 2x, 2 means mint 3x
   * @param _to Destination address
   */
  function mint(address _to) external nonReentrant onlyOwner {
    internalMint(_to, defaultURI);
  }

  function setTokenName(uint256 _tokenId, string memory _tokenName) external {
    require(ownerOf(_tokenId) == _msgSender(), "UNAUTHORIZED");
    _payToAddressERC20(namePrice);
    _tokenNameList[_tokenId] = _tokenName;
    emit TokenNameChanged(_tokenId, _tokenName);
  }

  function setTokenQuote(uint256 _tokenId, string memory _tokenQuote) external {
    require(ownerOf(_tokenId) == _msgSender(), "UNAUTHORIZED");
    _payToAddressERC20(quotePrice);
    _tokenQuoteList[_tokenId] = _tokenQuote;
    emit TokenQuoteChanged(_tokenId, _tokenQuote);
  }

  // Gui offer
  function initiateBreedingOffer(
    uint256 _senderTokenIds,
    uint256 _receiverTokenIds,
    address _receiver
  ) external {
    require(ownerOf(_senderTokenIds) == _msgSender(), "NOT_OWNED");
    require(ownerOf(_receiverTokenIds) == _receiver, "RCVR_NOT_OWNED");
    BreedingOfferInfo memory offerInfo = BreedingOfferInfo(
      _msgSender(),
      _receiver,
      _senderTokenIds,
      _receiverTokenIds,
      0
    );
    _offerIdCounter.increment();
    uint256 currentId = _offerIdCounter.current();
    _offerInfos[currentId] = offerInfo;
    EnumerableSet.add(_incomingOrders[_receiver], currentId);
    EnumerableSet.add(_outgoingOrders[_msgSender()], currentId);
  }

  // Huy offer
  function cancelOffer(uint256 _offerId) external {
    require(
      EnumerableSet.contains(_outgoingOrders[_msgSender()], _offerId),
      "UNAUTHORIZED"
    );
    require(_offerInfos[_offerId].status == 0, "UNCANCELLABLE");
    _offerInfos[_offerId].status == 2;
    EnumerableSet.remove(
      _incomingOrders[_offerInfos[_offerId].receiver],
      _offerId
    );
    EnumerableSet.remove(_outgoingOrders[_msgSender()], _offerId);
  }

  // Nguoi nhan chap nhan offer
  function acceptOffer(uint256 _offerId) external {
    require(
      EnumerableSet.contains(_incomingOrders[_msgSender()], _offerId),
      "UNAUTHORIZED"
    );

    require(_offerInfos[_offerId].status == 0, "UNACCEPTABLE");
    _offerInfos[_offerId].status == 1;
    EnumerableSet.remove(
      _incomingOrders[_offerInfos[_offerId].receiver],
      _offerId
    );
    EnumerableSet.remove(_outgoingOrders[_msgSender()], _offerId);
    _tokenIds.increment();

    uint256 childId = internalMint(_offerInfos[_offerId].sender, defaultURI);

    _breed(
      _offerInfos[_offerId].senderTokenIds,
      _offerInfos[_offerId].receiverTokenIds,
      childId
    );

    emit Breeded(childId);
  }

  /*╔══════════════════════════════╗
      ║            GETTERS           ║
      ╚══════════════════════════════╝*/

  function getCirculatingLimit() external view returns (uint256) {
    return circulatingLimit;
  }

  function getTokenName(uint256 _tokenId)
    external
    view
    returns (string memory)
  {
    return _tokenNameList[_tokenId];
  }

  function getTokenQuote(uint256 _tokenId)
    external
    view
    returns (string memory)
  {
    return _tokenQuoteList[_tokenId];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory _tokenURI = _uniqueNFTData[tokenId];

    string memory base = _baseURI();
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }
    // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(base, tokenId.toString()));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://gateway.ipfs.io/ipfs/";
  }

  function contractURI() public pure returns (string memory) {
    return
      "https://gateway.pinata.cloud/ipfs/QmXvqLak49dEb1u74u4Yw6gTcmHpS8HqxYskLAJCS4X4jQ?preview=1";
  }

  function getMetadata(uint256 _tokenId)
    external
    view
    returns (MoolaMetadata memory)
  {
    return _tokenInfo[_tokenId];
  }
}
