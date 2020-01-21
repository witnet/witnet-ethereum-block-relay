pragma solidity ^0.5.0;

/**
 * @title Block relay contract
 * @notice Contract to store/read block headers from the Witnet network
 * @author Witnet Foundation
pragma solidity ^0.5.0;
*/

contract TestBlockRelayV3 {

  struct MerkleRoots {
    // hash of the merkle root of the DRs in Witnet
    uint256 drHashMerkleRoot;
    // hash of the merkle root of the tallies in Witnet
    uint256 tallyHashMerkleRoot;
    // Points to previous vote
    uint256 previousVote;
  }
  struct Beacon {
    // hash of the last block
    uint256 blockHash;
    // epoch of the last block
    uint256 epoch;
  }

  // Address of the block pusher
  address witnet;
  // Last block reported
  Beacon public lastBlock;

  mapping (uint256 => MerkleRoots) public blocks;

  // Event emitted when a new block is posted to the contract
  event NewBlock(address indexed _from, uint256 _id);

  constructor() public{
    // Only the contract deployer is able to push blocks
    witnet = msg.sender;
  }

  // Only the owner should be able to push blocks
  modifier isOwner() {
    require(msg.sender == witnet, "Sender not authorized"); // If it is incorrect here, it reverts.
    _; // Otherwise, it continues.
  }


  /// @dev Verifies the validity of a PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function verifyDrPoi(
    uint256[] memory _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  public
  view
  returns(bool)
  {
    return true;
  }

  /// @dev Verifies the validity of a PoI against the tally merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the element
  /// @return true or false depending the validity
  function verifyTallyPoi(
    uint256[] memory _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  public
  view
  returns(bool)
  {
    return true;
  }
}
