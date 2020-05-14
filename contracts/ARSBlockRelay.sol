pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

import "./ActiveBridgeSetInterface.sol";
import "./BlockRelayInterface.sol";
import "bls-solidity/contracts/BN256G2.sol";


/**
 * @title Active Bridge Set Block relay contract
 * @notice Contract to store/read block headers from the Witnet network, implements BFT Finality bsaed on the Active Bridge Set (ABS)
 * @dev More information can be found here https://github.com/witnet/research/blob/master/bridge/docs/BFT_finality.md
 * DISCLAIMER: this is a work in progress, meaning the contract could be voulnerable to attacks
 * @author Witnet Foundation
 */
contract ARSBlockRelay is BlockRelayInterface {

  struct Beacon {
    // Hash of the last block
    uint256 blockHash;
    // Epoch of the last block
    uint256 epoch;
  }

  struct MerkleRoots {
    // Hash of the merkle root of the DRs in Witnet
    uint256 drHashMerkleRoot;
    // Hash of the merkle root of the tallies in Witnet
    uint256 tallyHashMerkleRoot;
    // Hash of the vote that this block extends
    uint256 previousVote;
  }

  // Struct with the hashes of a votation
  struct Hashes {
    uint256 blockHash;
    uint256 drMerkleRoot;
    uint256 tallyMerkleRoot;
    uint256 previousVote;
    uint256 epoch;
  }

  struct VoteInfo {
    // Information of a Block Candidate
    uint256 numberOfVotes;
    Hashes voteHashes;
  }

  struct PublicKeyCoordinates {
    // Coordinates of the public key in G2
    uint256 x1;
    uint256 x2;
    uint256 y1;
    uint256 y2;
  }

  // Needed for the constructor
  uint256 public witnetGenesis;
  uint256 public epochSeconds;
  uint256 public firstBlock;
  address public witnet;

  // Initializes the current epoch and the epoch in which it is valid to propose blocks
  uint256 public currentEpoch;
  uint256 public proposalEpoch;

  // Array with the votes for the proposed blocks
  uint256[] public candidates;

    // Last block reported
  Beacon public lastBlock;

  // Map the hash of the block to the merkle roots and the previousVote it extends
  mapping (uint256 => MerkleRoots) public blocks;

// Map an epoch to the finalized blockHash
  mapping(uint256 => uint256) internal epochFinalizedBlock;

  // Map a vote proposed to the number of votes received and its hashes
  mapping(uint256=> VoteInfo) internal voteInfo;

  // Map a publickKey to its coordinates in G2
  mapping(bytes=> PublicKeyCoordinates) internal pubKeyCoordinates;

  // Ensure block exists
  modifier blockExists(uint256 _id){
    require(blocks[_id].drHashMerkleRoot!=0, "Non-existing block");
    _;
  }

  // Ensure that neither Poi nor PoE are allowed if the epoch is pending
  modifier epochIsFinalized(uint256 _epoch){
    require(
      (epochFinalizedBlock[_epoch] != 0),
      "The block has not been finalized");
    _;
  }

// Ensure block does not exist
  modifier blockDoesNotExist(uint256 _id){
    require(blocks[_id].drHashMerkleRoot==0, "The block already existed");
    _;
  }

  constructor(
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock, address _wbiAddress) public{
    // Set the first epoch in Witnet plus the epoch duration when deploying the contract
    witnetGenesis = _witnetGenesis;
    epochSeconds = _epochSeconds;
    firstBlock = _firstBlock;
    witnet = msg.sender;
  }

  /// @dev Read the beacon of the last block inserted
  /// @return bytes to be signed by bridge nodes
  function getLastBeacon()
    external
    view
    override
  returns(bytes memory)
  {
    return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
  }

  /// @notice Returns the lastest epoch reported to the block relay.
  /// @return epoch
  function getLastEpoch() external view override returns(uint256) {
    return lastBlock.epoch;
  }

  /// @notice Returns the latest hash reported to the block relay
  /// @return blockhash
  function getLastHash() external view override returns(uint256) {
    return lastBlock.blockHash;
  }

  /// @dev Verifies if the contract is upgradable.
  /// @return true if the contract upgradable.
  function isUpgradable(address _address) external view override returns(bool) {
    if (_address == witnet) {
      return true;
    }
    return false;
  }

  /// @dev Verifies the validity of a PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function verifyDrPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  external
  view
  override
  blockExists(_blockHash)
  epochIsFinalized(currentEpoch)
  returns(bool)
  {
    uint256 drMerkleRoot = blocks[_blockHash].drHashMerkleRoot;
    return(verifyPoi(
      _poi,
      drMerkleRoot,
      _index,
      _element));
  }

  /// @dev Verifies the validity of a PoI against the tally merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the element
  /// @return true or false depending the validity
  function verifyTallyPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  external
  view
  override
  blockExists(_blockHash)
  returns(bool)
  {
    uint256 tallyMerkleRoot = blocks[_blockHash].tallyHashMerkleRoot;
    return(verifyPoi(
      _poi,
      tallyMerkleRoot,
      _index,
      _element));

  }

  

  /// @dev Proposes a block into the block relay
  /// @param _blockHash Hash of the block header
  /// @param _epoch Epoch for which the block is proposed
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  /// @param _arsMerkleRoot Merkle root belonging to the ars members
  /// @param _aggregatedSig Signatures aggregated
  /// @param _publicKeys Public Keys of the ars members who signed
  /// @param _merklePath Merkle path of the ars members
  /// @param _previousVote Hash of block's hashes proposed in a previous epoch // // Aggregate the _publicKeys
    // uint256 n = _publicKeys.length;
    // for (uint i = 0; i < n - 1; i++) {
    //   uint256[4] sum =
    //   bn128_add(_publicKeys[i, i+1])
    //   _publicKeys[i] + _publicKeys[i + 1];
    // }
  function proposeBlock(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _arsMerkleRoot,
    bytes calldata _aggregatedSig,
    bytes[] calldata _publicKeys,
    uint256[] calldata _merklePath,
    uint256 _previousVote
    )
    external
    // epochValid(_epoch)
    blockDoesNotExist(_blockHash)
    returns(bytes32)
  {
    // Verify the public keys correpond to members of the ARS
    for (uint i = 0; i < _publicKeys.length; i++) {
      bytes memory publickKey = _publicKeys[i];
      require(
        verifyArsMembership(
          _merklePath,
          _arsMerkleRoot,
          // the index is the position in publickeys
          i,
          publickKey
      ),
        "Some of the public keys are not from ARS members");
    }

    // 1. Check if the public keys have already been counted
    // 2. Agreggate the public keys P
    // 3. Calculate H(m) = H(_blockHash)
    // 4. Check the paring e(S,G2) = e(H(m), P)
    // 5. Create the vote and its information
    // 6. Update the vote count and post new block if it reaches 2/3 of the ABS


    // Define the vote
    uint256 vote = createVote(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote
      //2**_merklePath.length
    );

    updateVoteCount(vote, _publicKeys.length, 2**_merklePath.length);


  }

  /// @dev Verifies if an address is part of the ARS
  /// @param _merklePath the proof of inclusion as [sibling1, sibling2,..]
  /// @param _arsMerkleRoot the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _publickKey the leaf to be verified
  /// @return true or false depending the validity
  function verifyArsMembership(
    uint256[] memory _merklePath,
    uint256 _arsMerkleRoot,
    uint256 _index,
    bytes memory  _publickKey)
  internal
  pure
  returns(bool)
  {
    return(verifyPoi(
      _merklePath,
      _arsMerkleRoot,
      _index,
      uint256(sha256(_publickKey))
      ));
  }

  /// @dev Create vote
  /// @param _blockHash Hash of the block headerPost
  /// @param _epoch Witnet epoch to which the block belongs to
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  /// @param _previousVote Hash of block's hashes proposed in the previous epoch
  function createVote(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote)
    //uint256 _absMembers)
    private
    blockDoesNotExist(_blockHash)
    returns(uint256)
  {

    // Define the vote
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));

    if (voteInfo[vote].numberOfVotes == 0) {
      // Add the vote to candidates
      candidates.push(vote);
      // Mapping the vote into its hashes
      voteInfo[vote].voteHashes.blockHash = _blockHash;
      voteInfo[vote].voteHashes.drMerkleRoot = _drMerkleRoot;
      voteInfo[vote].voteHashes.tallyMerkleRoot = _tallyMerkleRoot;
      voteInfo[vote].voteHashes.previousVote = _previousVote;
      voteInfo[vote].voteHashes.epoch = _epoch;
    }

    return vote;
  }

  /// @dev Updates the count of votes
  /// @param _vote vote proposed
  /// @param _numberOfVotes number of votes recieved in proposingBlock
  /// @param _absMembers number of members of the ABS
  function updateVoteCount(uint256 _vote, uint256 _numberOfVotes, uint256 _absMembers)
    private
  {
    voteInfo[_vote].numberOfVotes = voteInfo[_vote].numberOfVotes + _numberOfVotes;
    // Add the votes
    if (3*voteInfo[_vote].numberOfVotes > 2*_absMembers) {
      postNewBlock(
        _vote,
        voteInfo[_vote].voteHashes.blockHash,
        voteInfo[_vote].voteHashes.epoch,
        voteInfo[_vote].voteHashes.drMerkleRoot,
        voteInfo[_vote].voteHashes.tallyMerkleRoot,
        voteInfo[_vote].voteHashes.previousVote
      );
    }
  }

  /// @dev aggregates the public keys to be used in BLs
  /// @param _publicKeys Public Keys to be aggregated
  function publickeysAggregation(
    bytes[] memory _publicKeys
    )
    private
    returns(uint256[4] memory)
  {
    decodePublicKeys(_publicKeys);
    uint256 n = _publicKeys.length;
    uint256[4] memory aggregatedPubKey;
    aggregatedPubKey = [
      pubKeyCoordinates[_publicKeys[0]].x1,
      pubKeyCoordinates[_publicKeys[0]].x2,
      pubKeyCoordinates[_publicKeys[0]].y1,
      pubKeyCoordinates[_publicKeys[0]].y2
    ];
    for (uint i = 1; i < n; i++) {
      aggregatedPubKey = BN256G2.ECTwistAdd(
         aggregatedPubKey[0],
         aggregatedPubKey[1],
         aggregatedPubKey[2],
         aggregatedPubKey[3],
         pubKeyCoordinates[_publicKeys[i]].x1,
         pubKeyCoordinates[_publicKeys[i]].x2,
         pubKeyCoordinates[_publicKeys[i]].y1,
         pubKeyCoordinates[_publicKeys[i]].y2
      );
      return aggregatedPubKey;
    }
  }

  /// @dev Decodes a public key and adds the coordinates in G2
  /// @param _publicKeys Public Key of the ars members who signed
  function decodePublicKeys(
    bytes[] memory _publicKeys
    )
    private
    returns(uint256[4] memory)
  {
    uint256 n = _publicKeys.length;

    for (uint i = 0; i < n; i++) {
      bytes memory publicKey = _publicKeys[i];
      bytes32 x1;
      bytes32 x2;
      bytes32 y1;
      bytes32 y2;
      assembly {
            x1 := mload(add(publicKey, 0x20))
            x2 := mload(add(publicKey, 0x40))
            y1 := mload(add(publicKey, 0x60))
            y2 := mload(add(publicKey, 0x40))
      }

      pubKeyCoordinates[publicKey].x1 = uint256(x1);
      pubKeyCoordinates[publicKey].x2 = uint256(x2);
      pubKeyCoordinates[publicKey].y1 = uint256(y1);
      pubKeyCoordinates[publicKey].y2 = uint256(y2);
    }
  }

  /// @dev Post new block into the block relay
  /// @param _vote Vote created when the block was proposed
  /// @param _blockHash Hash of the block headerPost
  /// @param _epoch Witnet epoch to which the block belongs to
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  /// @param _previousVote Hash of block's hashes proposed in the previous epoch
  function postNewBlock(
    uint256 _vote,
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote)
    private
    blockDoesNotExist(_blockHash)
  {
  }

  /// @dev Verifies the validity of a PoI
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _root the merkle root
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function verifyPoi(
    uint256[] memory _poi,
    uint256 _root,
    uint256 _index,
    uint256 _element)
  private pure returns(bool)
  {
    uint256 tree = _element;
    uint256 index = _index;
    // We want to prove that the hash of the _poi and the _element is equal to _root
    // For knowing if concatenate to the left or the right we check the parity of the the index
    for (uint i = 0; i < _poi.length; i++) {
      if (index%2 == 0) {
        tree = uint256(sha256(abi.encodePacked(tree, _poi[i])));
      } else {
        tree = uint256(sha256(abi.encodePacked(_poi[i], tree)));
      }
      index = index >> 1;
    }
    return _root == tree;
  }

}