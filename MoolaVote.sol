import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/INFTCore.sol";

/// @title ERC20MockContract
/// @notice
///
/**
 */
contract MoolaVote is OwnableUpgradeable, PausableUpgradeable {
  IERC20Upgradeable internal dairy;
  IERC721EnumerableUpgradeable internal moolaNFT;
  address internal recipient;

  uint256 internal proposalFee;
  uint256 internal voteFee;

  uint256 internal proposalIndex;

  struct TitleProposal {
    string title;
    address proposer;
    uint256 currentHolder;
    uint256 currentMaxVote;
  }

  EnumerableSet.Bytes32Set internal titleList;

  mapping(uint256 => TitleProposal) internal proposalIds;
  mapping(uint256 => EnumerableSet.UintSet) internal holdingTitles;

  mapping(uint256 => mapping(uint256 => uint256)) internal countingVotes;

  event ProposalCreated(
    uint256 indexed proposalId,
    address proposer,
    string title
  );

  event VoteSubmitted(
    uint256 indexed proposalId,
    address voter,
    uint256 nominee
  );

  function initialize(
    address _dairy,
    address _moolaNFT,
    address _recipient
  ) external initializer {
    __Ownable_init();
    __Pausable_init();
    dairy = IERC20Upgradeable(_dairy);
    moolaNFT = IERC721EnumerableUpgradeable(_moolaNFT);
    recipient = _recipient;
    proposalFee = 100 * 1e18;
    voteFee = 2 * 1e18;
    proposalIndex = 0;
  }

  function setProposalFee(uint256 _newFee) external onlyOwner {
    proposalFee = _newFee;
  }

  function setVoteFee(uint256 _newFee) external onlyOwner {
    voteFee = _newFee;
  }

  function stringToBytes32(string memory source)
    internal
    pure
    returns (bytes32 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }

  function createProposal(string memory _title) external {
    proposalIndex = proposalIndex + 1;
    require(
      !EnumerableSet.contains(titleList, stringToBytes32(_title)),
      "Duplicate title"
    );

    dairy.transferFrom(msg.sender, recipient, proposalFee);
    EnumerableSet.add(titleList, stringToBytes32(_title));
    TitleProposal memory title = TitleProposal({
      title: _title,
      proposer: msg.sender,
      currentHolder: 0,
      currentMaxVote: 0
    });
    proposalIds[proposalIndex] = title;

    emit ProposalCreated(proposalIndex, msg.sender, _title);
  }

  function vote(uint256 _proposalId, uint256 _nominee) external {
    require(_proposalId <= proposalIndex, "Invalid index");
    dairy.transferFrom(msg.sender, recipient, voteFee);

    countingVotes[_proposalId][_nominee] += 1;
    if (
      countingVotes[_proposalId][_nominee] ==
      proposalIds[proposalIndex].currentMaxVote
    ) {
      if (proposalIds[proposalIndex].currentHolder != 0) {
        EnumerableSet.remove(
          holdingTitles[proposalIds[proposalIndex].currentHolder],
          _proposalId
        );
        proposalIds[proposalIndex].currentHolder = 0;
      }
    }
    if (
      countingVotes[_proposalId][_nominee] >
      proposalIds[proposalIndex].currentMaxVote
    ) {
      proposalIds[proposalIndex].currentHolder = _nominee;
      proposalIds[proposalIndex].currentMaxVote = countingVotes[_proposalId][
        _nominee
      ];
      EnumerableSet.add(
        holdingTitles[proposalIds[proposalIndex].currentHolder],
        _proposalId
      );
    }

    emit VoteSubmitted(_proposalId, msg.sender, _nominee);
  }

  function getCurrentHoldingTitleLengthOfToken(uint256 _tokenId)
    external
    view
    returns (uint256)
  {
    return EnumerableSet.length(holdingTitles[_tokenId]);
  }

  function getCurrentHoldingTitleOfTokenAtIndex(
    uint256 _tokenId,
    uint256 _index
  ) external view returns (uint256) {
    return EnumerableSet.at(holdingTitles[_tokenId], _index);
  }

  function getProposalCount() external view returns (uint256) {
    return proposalIndex;
  }

  function getProposal(uint256 _index)
    external
    view
    returns (TitleProposal memory)
  {
    return proposalIds[_index];
  }

  function getProposalTitle(uint256 _index)
    external
    view
    returns (string memory)
  {
    return proposalIds[_index].title;
  }

  function getProposalHolder(uint256 _index) external view returns (uint256) {
    return proposalIds[_index].currentHolder;
  }

  function getVotingCountForToken(uint256 _proposalId, uint256 _tokenId)
    external
    view
    returns (uint256)
  {
    return countingVotes[_proposalId][_tokenId];
  }
}
