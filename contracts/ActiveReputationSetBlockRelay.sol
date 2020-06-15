pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "./ActiveBridgeSetInterface.sol";
import "./BlockRelayInterface.sol";
import "bls-solidity/contracts/BN256G2.sol";
import "bls-solidity/contracts/BN256G1.sol";


/**
 * @title Active Bridge Set Block relay contract
 * @notice Contract to store/read block headers from the Witnet network, implements BFT Finality bsaed on the Active Reputation Set (ARS)
 * @dev More information can be found here https://github.com/witnet/research/blob/master/bridge/docs/BFT_finality.md
 * DISCLAIMER: this is a work in progress, meaning the contract could be voulnerable to attacks
 * @author Witnet Foundation
 */
contract ActiveReputationSetBlockRelay is BlockRelayInterface {


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
    uint32 blockIndex;
    uint256 drMerkleRoot;
    uint256 tallyMerkleRoot;
    uint256 previousVote;
    uint32 lastBlockIndex;
    uint256 epoch;
  }

  // Struct with the hashes of a votation
  struct Hashes2 {
    uint64 arsLength;
    uint256 arsMerkleRoot;
    uint256 drMerkleRoot;
    uint32 blockIndex;
    uint256 lastBlockHash;
    uint256 previousLastBlockHash;
    uint256 tallyMerkleRoot;
  }

  struct VoteInfo {
    // Information of a Block Candidate
    uint256 numberOfVotes;
    Hashes voteHashes;
  }


  struct VoteInf {
    // Information of a Block Candidate
    uint256 numberOfVotes;
    Hashes2 voteHashes;
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

// Map a vote proposed to the number of votes received and its hashes
  mapping(uint256=> VoteInf) internal voteInf;

  // Map a publicKey to its coordinates in G2
  mapping(bytes=> PublicKeyCoordinates) internal pubKeyCoordinates;

  mapping(bytes => uint32) internal lastBlockProposed;

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

  // Ensure block does not exist
  modifier onlyOwner(){
    require(msg.sender == witnet, "not allowed to call this function");
    _;
  }


  constructor(
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock) public{
    // Set the first epoch in Witnet plus the epoch duration when deploying the contract
    witnetGenesis = _witnetGenesis;
    epochSeconds = _epochSeconds;
    firstBlock = _firstBlock;
    witnet = msg.sender;
  }

  /// @dev Read the beacon of the last block inserted.
  /// @return bytes to be signed by bridge nodes.
  function getLastBeacon()
    external
    view
    override
  returns(bytes memory)
  {
    return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
  }

  /// @notice Returns the lastest epoch reported to the block relay.
  /// @return epoch.
  function getLastEpoch() external view override returns(uint256) {
    return lastBlock.epoch;
  }

  /// @notice Returns the latest hash reported to the block relay.
  /// @return blockhash.
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

  /// @dev Verifies the validity of a PoI against the DR merkle root.
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..].
  /// @param _blockHash the blockHash.
  /// @param _index the index in the merkle tree of the element to verify.
  /// @param _element the leaf to be verified.
  /// @return true or false depending the validity.
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

  /// @dev Verifies the validity of a PoI against the tally merkle root.
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..].
  /// @param _blockHash the blockHash.
  /// @param _index the index in the merkle tree of the element to verify.
  /// @param _element the element.
  /// @return true or false depending the validity.
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

  /// @dev Stores a public key coordinates in G2 and assigns them to a reference.
  /// @param _publicKey Public Key of the ars members who signed.
  function storeCoordinatesPublicKeys(
    bytes memory _publicKey, uint256[4] memory _coordinates
    )
    public
    returns(uint256[4] memory)
  {
    pubKeyCoordinates[_publicKey].x1 = _coordinates[0];
    pubKeyCoordinates[_publicKey].x2 = _coordinates[1];
    pubKeyCoordinates[_publicKey].y1 = _coordinates[2];
    pubKeyCoordinates[_publicKey].y2 = _coordinates[3];
  }

  /// @dev Verifies the pairing e(S,G2)= e(H(m), P), where S is the aggreagted signature
  /// and P is the aggregated public key.
  /// @param _message the message that has been signed m.
  /// @param _signature the aggregated signature S.
  /// @param _publicKeyAggregated the agregated public key P.
  function verifyBlsSignature(
    bytes memory _message,
    bytes memory _signature,
    uint256[4] memory _publicKeyAggregated)
    public
    returns(bool)
  {
    uint256[2] memory s;
    (s[0], s[1]) = BN256G1.fromCompressed(_signature);


    // Coordinates of the generator point of G2
    uint256 g2xx = uint256(0x198E9393920D483A7260BFB731FB5D25F1AA493335A9E71297E485B7AEF312C2);
    uint256 g2xy = uint256(0x1800DEEF121F1E76426A00665E5C4479674322D4F75EDADD46DEBD5CD992F6ED);
    uint256 g2yx = uint256(0x275dc4a288d1afb3cbb1ac09187524c7db36395df7be3b99e673b13a075a65ec);
    uint256 g2yy = uint256(0x1d9befcd05a5323e6da4d435f3b617cdb3af83285c2df711ef39c01571827f9d);


    // Coordinates of the message hash H(m)
    uint256[2] memory hm;
    (hm[0], hm[1]) = BN256G1.hashToTryAndIncrement(_message);

    bool check = BN256G1.bn256CheckPairing([
      hm[0],
      hm[1],
      _publicKeyAggregated[1],
      _publicKeyAggregated[0],
      _publicKeyAggregated[3],
      _publicKeyAggregated[2],
      s[0],
      s[1],
      g2xx,
      g2xy,
      g2yx,
      g2yy
    ]);

    return check;
  }

  /// @dev Verifies the pairing e(S,G2)= e(H(m), P), where S is the aggreagted signature
  /// and P is the aggregated public key.
  /// @param _blockHashes the message that has been signed m.
  /// @param _signature the aggregated signature S.
  /// @param _publicKeys the agregated public key P.
  function checkBlsSignature(
    uint256[7] memory _blockHashes,
    bytes memory _signature,
    bytes[] memory _publicKeys)
    internal
    returns(bool)
  {
    bytes memory messageBytes = calculateSuperblock(
      uint64(_blockHashes[0]),
       _blockHashes[1],
        _blockHashes[2],
        uint32(_blockHashes[3]),
       _blockHashes[4],
        _blockHashes[5],
        _blockHashes[6]
    );

    uint256 message = uint256(
       sha256(
        abi.encodePacked(
     uint64(_blockHashes[0]),
       _blockHashes[1],
        _blockHashes[2],
        uint32(_blockHashes[3]),
       _blockHashes[4],
        _blockHashes[5],
        _blockHashes[6])));
    
    uint256[4] memory pubKeyAgg;
    pubKeyAgg = publickeysAggregation(_publicKeys);


    require(
      verifyBlsSignature(
        messageBytes,
        _signature,
        pubKeyAgg
        ),
      "not valid BLS signature");

    if (voteInfo[message].numberOfVotes == 0) {
      // Add the vote to candidates
      candidates.push(message);
      // Mapping the vote into its hashes
      voteInf[message].voteHashes.arsLength = uint64(_blockHashes[0]);
      voteInf[message].voteHashes.arsMerkleRoot = _blockHashes[1];
      voteInf[message].voteHashes.drMerkleRoot = _blockHashes[2];
      voteInf[message].voteHashes.blockIndex = uint32(_blockHashes[3]);
      voteInf[message].voteHashes.lastBlockHash = _blockHashes[4];
      voteInf[message].voteHashes.previousLastBlockHash = _blockHashes[5];
      voteInf[message].voteHashes.tallyMerkleRoot = _blockHashes[6];

    }

    for (uint i = 0; i < _publicKeys.length; i++) {
      uint64 numberOfNewVotes;
      if(lastBlockProposed[_publicKeys[i]] < uint32(_blockHashes[3])) {
        numberOfNewVotes++;
      }

    updateVoteCount2(message, numberOfNewVotes, uint64(_blockHashes[0]));

    }

  }

  /// @dev aggregates the public keys to be used in BLS.
  /// @param _publicKeys Public Keys to be aggregated.
  function publickeysAggregation(bytes[] memory _publicKeys)
    public
    returns(uint256[4] memory)
  {
    uint256 n = _publicKeys.length;
    uint256[4] memory aggregatedPubKey;
    aggregatedPubKey = [
      pubKeyCoordinates[_publicKeys[0]].x1,
      pubKeyCoordinates[_publicKeys[0]].x2,
      pubKeyCoordinates[_publicKeys[0]].y1,
      pubKeyCoordinates[_publicKeys[0]].y2
    ];

    for (uint i = 1; i < n; i++) {
      (aggregatedPubKey[0], aggregatedPubKey[1], aggregatedPubKey[2], aggregatedPubKey[3]) = BN256G2.ecTwistAdd(
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

  /// @dev Verifies if an address is part of the ARS.
  /// @param _merklePath the proof of inclusion as [sibling1, sibling2,..].
  /// @param _arsMerkleRoot the blockHash.
  /// @param _index the index in the merkle tree of the element to verify.
  /// @param _publicKey the leaf to be verified.
  /// @return true or false depending the validity.
  function verifyArsMembership(
    uint256[] memory _merklePath,
    uint256 _arsMerkleRoot,
    uint256 _index,
    bytes memory  _publicKey)
  internal
  virtual
  returns(bool)
  {
    return(verifyPoi(
      _merklePath,
      _arsMerkleRoot,
      _index,
      uint256(sha256(_publicKey))
      ));
  }

  /// @dev Verifies if an address is part of the ARS.
  /// @param _merklePath the proof of inclusion as [sibling1, sibling2,..].
  /// @param _arsMerkleRoot the blockHash.
  /// @param _publicKeys the leaf to be verified.
  function verifyArsMembership2(
    uint256[] memory _merklePath,
    uint256 _arsMerkleRoot,
    bytes[] memory  _publicKeys)
  internal
  pure
  {
    for (uint i = 0; i < _publicKeys.length; i++) {
    bytes memory publicKey = _publicKeys[i];
    require(verifyPoi(
      _merklePath,
      _arsMerkleRoot,
      i,
      uint256(sha256(publicKey))
      ), "Some of the public keys are not ARS members");
  }
  }

  /// @dev Updates the count of votes.
  /// @param _vote vote proposed.
  /// @param _numberOfVotes number of votes recieved in proposeBlock.
  /// @param _arsMembers number of members of the ARS.
  function updateVoteCount(uint256 _vote, uint256 _numberOfVotes, uint256 _arsMembers)
    internal
  {
    voteInfo[_vote].numberOfVotes = voteInfo[_vote].numberOfVotes + _numberOfVotes;

    if (3*voteInfo[_vote].numberOfVotes > 2*_arsMembers) {
      postNewBlock(
        voteInfo[_vote].voteHashes.blockHash,
        voteInfo[_vote].voteHashes.epoch,
        voteInfo[_vote].voteHashes.drMerkleRoot,
        voteInfo[_vote].voteHashes.tallyMerkleRoot
      );
    }
  }

  /// @dev Updates the count of votes.
  /// @param _vote vote proposed.
  /// @param _numberOfVotes number of votes recieved in proposeBlock.
  /// @param _arsMembers number of members of the ARS.
  function updateVoteCount2(uint256 _vote, uint256 _numberOfVotes, uint64 _arsMembers)
    internal
  {
    voteInfo[_vote].numberOfVotes = voteInfo[_vote].numberOfVotes + _numberOfVotes;

    if (3*voteInfo[_vote].numberOfVotes > 2*_arsMembers) {
      postNewBlock(
        voteInf[_vote].voteHashes.lastBlockHash,
        voteInfo[_vote].voteHashes.epoch,
        voteInfo[_vote].voteHashes.drMerkleRoot,
        voteInfo[_vote].voteHashes.tallyMerkleRoot
      );
    }
  }


  /// @dev Proposes a block into the block relay.
  /// @param _blockHash blockHash of the block proposed.
  /// @param _epoch Witnet epoch to which the block belongs to.
  /// @param _drMerkleRoot Merkle root belonging to the data requests.
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies.
  /// @param _previousVote Hash of block's hashes proposed in the previous epoch.
  /// @param _arsLength Number of members of the ARS.
  /// @param _arsMerkleRoot Merkle root belonging to the ARS membership.
  /// @param _arsMerklePath merklePath to verify the membership to the ARS.
  /// @param _aggregatedSig aggregated signature (uncompressed format) from the proposers.
  /// @param _publicKeys public keys of the proposers, members of the ARS.
  function proposeBlock(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote,
    uint64 _arsLength,
    uint256 _arsMerkleRoot,
    uint256[] memory _arsMerklePath,
    bytes memory _aggregatedSig,
    bytes[] memory _publicKeys
    )
    private
    blockDoesNotExist(_blockHash)
    returns(uint256)
  {
    // 1. Check if the _publickeys are ARS members
    for (uint i = 0; i < _publicKeys.length; i++) {
      bytes memory publicKey = _publicKeys[i];
      require(
        verifyArsMembership(
          _arsMerklePath,
          _arsMerkleRoot,
          // the index is the position in publickeys
          i,
          publicKey
      ),
        "Some of the public keys are not ARS members");
    }

    // 2. Aggregate the _publicKeys
    uint256[4] memory pubKeyAgg;
    pubKeyAgg = publickeysAggregation(_publicKeys);

    // Define the vote
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));

    // 3. Verify the BLS signature with signatures and public keys aggregated
    require(
      verifyBlsSignature(
        abi.encode(_blockHash),
        _aggregatedSig,
        pubKeyAgg
        ),
      "not valid BLS signature");

    // 4. Add vote information if it's a new vote
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

    // 5. Update the vote count
    updateVoteCount(vote, _publicKeys.length, _arsLength);

  }

  /// @dev Proposes a block into the block relay.
  /// @param _blockHashes merklePath to verify the membership to the ARS.
  /// @param _arsMerklePath merklePath to verify the membership to the ARS.
  /// @param _aggregatedSig aggregated signature (uncompressed format) from the proposers.
  /// @param _publicKeys public keys of the proposers, members of the ARS.
  function proposeBlock2(
    uint256[7] memory _blockHashes,
    // uint32 _blockIndex,
    // uint256 _drMerkleRoot,
    // uint32 _lastBlockIndex,
    // uint32 _previousLastBlockIntex,
    // uint64 _arsLength,
    // uint256 _arsMerkleRoot,
    uint256[] memory _arsMerklePath,
    bytes memory _aggregatedSig,
    bytes[] memory _publicKeys
    )
    public
    blockDoesNotExist(_blockHashes[3])
    onlyOwner()
  {
    // 1. Check if the _publickeys are ARS members
     for (uint i = 0; i < _publicKeys.length; i++) {
       bytes memory publicKey = _publicKeys[i];
       require(
        verifyArsMembership(
           _arsMerklePath,
          _blockHashes[1],
          // the index is the position in publickeys
          i,
          publicKey
      ),
         "Some of the public keys are not ARS members");
     }

    // // 2. Aggregate the _publicKeys
    // uint256[4] memory pubKeyAgg;
    // pubKeyAgg = publickeysAggregation(_publicKeys);

    checkBlsSignature(_blockHashes, _aggregatedSig, _publicKeys);

    // Define the vote
    //  uint256 vote = uint256(
    //    sha256(
    //      abi.encodePacked(
    //    _blockHashes[0],
    //    _blockHashes[1],
    //    _blockHashes[2],
    //    _blockHashes[3],
    //    _blockHashes[4],
    //    _blockHashes[5],
    //    _tallyMerkleRoot)));
       //_blockHashes[6])));

    // // 3. Verify the BLS signature with signatures and public keys aggregated
    // require(
    //   verifyBlsSignature(
    //     abi.encode(vote),
    //     _aggregatedSig,
    //     pubKeyAgg
    //     ),
    //   "not valid BLS signature");

    // // 4. Add vote information if it's a new vote
    // if (voteInfo[vote].numberOfVotes == 0) {
    //   // Add the vote to candidates
    //   candidates.push(vote);
    //   // Mapping the vote into its hashes
    //   voteInfo[vote].voteHashes.blockIndex = _blockIndex;
    //   voteInfo[vote].voteHashes.drMerkleRoot = _drMerkleRoot;
    //   voteInfo[vote].voteHashes.tallyMerkleRoot = _tallyMerkleRoot;
    //   voteInfo[vote].voteHashes.lastBlockIndex = _lastBlockIndex;
    //   voteInfo[vote].voteHashes.epoch = _epoch;
    // }

    // // 5. Update the vote count
    // updateVoteCount(vote, _publicKeys.length, _arsLength);

  }

function calculateSuperblock(
 uint64 _arsLength,
  uint256 _arsMerkleRoot,
  uint256 _drMerkleRoot,
  uint32 _blockIndex,
  uint256 _lastBlockHash,
  uint256 _previousLastBlockHash,
  uint256 _tallyMerkleRoot
) internal virtual returns(bytes memory) {
  uint256 superblock = uint256(
       sha256(
        abi.encodePacked(
      _arsLength,
      _arsMerkleRoot,
      _drMerkleRoot,
      _blockIndex,
      _lastBlockHash,
      _previousLastBlockHash,
      _tallyMerkleRoot)));

  return abi.encode(superblock);
}

  /// @dev Post new block into the block relay.
  /// @param _blockHash Hash of the block headerPost.
  /// @param _epoch Witnet epoch to which the block belongs to.
  /// @param _drMerkleRoot Merkle root belonging to the data requests.
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies.
  function postNewBlock(
    //uint256 _vote,
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot)
    //uint256 _lastBlockIndex)
    private
    blockDoesNotExist(_blockHash)
  {
    uint256 id = _blockHash;
    lastBlock.blockHash = id;
    lastBlock.epoch = _epoch;
    blocks[id].drHashMerkleRoot = _drMerkleRoot;
    blocks[id].tallyHashMerkleRoot = _tallyMerkleRoot;
  }

  /// @dev Verifies the validity of a PoI.
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..].
  /// @param _root the merkle root.
  /// @param _index the index in the merkle tree of the element to verify.
  /// @param _element the leaf to be verified.
  /// @return true or false depending the validity.
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