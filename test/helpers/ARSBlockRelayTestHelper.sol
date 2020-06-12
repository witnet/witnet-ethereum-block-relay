pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "../../contracts/ActiveReputationSetBlockRelay.sol";
import "bls-solidity/contracts/BN256G2.sol";
import "bls-solidity/contracts/BN256G1.sol";



/**
 * @title Test Helper for the new ARS block Relay contract
 * @dev The aim of this contract is to raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */
contract ARSBlockRelayTestHelper is ActiveReputationSetBlockRelay {

  ActiveReputationSetBlockRelay public br;
  uint256 public timestamp;

  event Votation(uint256 _vote);
  event AbiHash(bytes _hash);

  constructor (
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock)
  ActiveReputationSetBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock) public {}

  function _fromCompressed(bytes memory _point) public returns(uint256[2] memory) {
    uint256[2] memory s;
    (s[0], s[1]) = BN256G1.fromCompressed(_point);
    return s;
  }

  function _aggregateSignatureCoordinates(uint256[4] memory input) public returns (uint256[2] memory) {
    uint256[2] memory result;
    (result[0], result[1]) = BN256G1.add(input);
    return result;
  }

  function _aggregateSignature(bytes[] memory _signatures) public returns (uint256[2] memory) {
    uint256[2] memory aggregatedSignature = _fromCompressed(_signatures[0]);
    for (uint i = 1; i < _signatures.length; i++) {
      aggregatedSignature = _aggregateSignatureCoordinates(
        [
          aggregatedSignature[0],
          aggregatedSignature[1],
          _fromCompressed(_signatures[i])[0],
          _fromCompressed(_signatures[i])[1]
        ]
      );
    }
    return aggregatedSignature;
  }

  function _proposeBlock(
    bytes memory _message,
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote,
    uint256 _arsMerkleRoot,
    uint256[] memory _merklePath,
    uint256[2] memory _aggregatedSig,
    bytes[] memory _publicKeys
    )
    public
    returns(uint256)
  {
     // Aggregate the _publicKeys
    uint256[4] memory pubKeyAgg;
    pubKeyAgg = publickeysAggregation(_publicKeys);
    emit Votation(_blockHash);
    // Define the vote
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));

    //  Verify the BLS signature with signature and public key aggregated
    require(
      _verifyBlsSignature(
        _message,
        [_aggregatedSig[0], _aggregatedSig[1]],
        pubKeyAgg
        ),
      "not valid BLS signature");

    // Add vote information if it's a new vote
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

    // Update the vote count
    updateVoteCount(vote, _publicKeys.length, 2**_merklePath.length);
    return(_blockHash);

  }

  function _verifyBlsSignature(
    // Very similar to verifyBlsSignature but with the signature uncompressed as input
    bytes memory _message,
    uint256[2] memory _signature,
    uint256[4] memory _publicKeyAggregated) public returns(bool)
    {

    // Coordinates of the generator point of G2
    uint256 g2xx = uint256(0x198E9393920D483A7260BFB731FB5D25F1AA493335A9E71297E485B7AEF312C2);
    uint256 g2xy = uint256(0x1800DEEF121F1E76426A00665E5C4479674322D4F75EDADD46DEBD5CD992F6ED);
    uint256 g2yx = uint256(0x275dc4a288d1afb3cbb1ac09187524c7db36395df7be3b99e673b13a075a65ec);
    uint256 g2yy = uint256(0x1d9befcd05a5323e6da4d435f3b617cdb3af83285c2df711ef39c01571827f9d);

    // Coordinates of the message hash H(m)
    uint256[2] memory hm;
    (hm[0], hm[1]) = BN256G1.hashToTryAndIncrement(_message);

    bool check = BN256G1.bn256CheckPairing([
      //uint256(s1),
      //uint256(s2),
      hm[0],
      hm[1],
      _publicKeyAggregated[1],
      _publicKeyAggregated[0],
      _publicKeyAggregated[3],
      _publicKeyAggregated[2],
      _signature[0],
      _signature[1],
      g2xx,
      g2xy,
      g2yx,
      g2yy
    ]);

    return check;
  }

function _calculateSuperblock(
  uint64 _arsLength,
  uint256 _arsMerkleRoot,
  uint256 _drMerkleRoot,
  uint32 _blockIndex,
  uint256 _lastBlockHash,
  uint256 _previousLastBlockHash,
  uint256 _tallyMerkleRoot
) public returns(uint256) {
  bytes memory abihash = abi.encodePacked(
      _arsLength,
      _arsMerkleRoot,
      _drMerkleRoot,
      _blockIndex,
      _lastBlockHash,
      _previousLastBlockHash,
      _tallyMerkleRoot);

  emit AbiHash(abihash);
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

  return superblock;
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
  override
  returns(bool)
  {
    return true;
  }

function calculateSuperblock(
 uint64 _arsLength,
  uint256 _arsMerkleRoot,
  uint256 _drMerkleRoot,
  uint32 _blockIndex,
  uint256 _lastBlockHash,
  uint256 _previousLastBlockHash,
  uint256 _tallyMerkleRoot
) internal override returns(uint256) {
  uint256 superBlock = 126862285106277;
  return superBlock;
}

}