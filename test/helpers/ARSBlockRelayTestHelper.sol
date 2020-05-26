pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

import "../../contracts/ActiveReputationSetBlockRelay.sol";
import "bls-solidity/contracts/BN256G2.sol";
import "bls-solidity/contracts/BN256G1.sol";



/**
 * @title Test Helper for the new block Relay contract
 * @dev The aim of this contract is to raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */
contract ARSBlockRelayTestHelper is ActiveReputationSetBlockRelay {

  ActiveReputationSetBlockRelay public br;
  uint256 public timestamp;

  constructor (
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock)
  ActiveReputationSetBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock) public {}

  function toBytes(uint256[4] memory _publicKey) public returns(bytes memory) {
    // for (uint i = 0; i < 3; i++) {
    //   bytes pubKey;

    bytes memory pubKey = abi.encodePacked(_publicKey[0],_publicKey[1], _publicKey[2], _publicKey[3]);
    //}
    return(pubKey);
  }


  function _fromCompressed(bytes memory _point) public returns(uint256[2] memory) {
    uint256[2] memory s = BN256G1.fromCompressed(_point);
    return s;
  }


  function _aggregateSignature(uint256[4] memory input) public returns (uint256[2] memory) {
    uint256[2] memory result = BN256G1.add(input);
    return result;
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

    // 3. Verify the BLS signature with signature and public key aggregated
    require(
      _verifyBlsSignature(
        _message,
        [_aggregatedSig[0], _aggregatedSig[1]],
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
    updateVoteCount(vote, _publicKeys.length, 2**_merklePath.length);

  }

  function _verifyBlsSignature(bytes memory _message,
    uint256[2] memory _signature,
    uint256[4] memory _publicKeyAggregated) public returns(bool) {
 // Get the coordinates of the signature aggreagetd
  

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


}