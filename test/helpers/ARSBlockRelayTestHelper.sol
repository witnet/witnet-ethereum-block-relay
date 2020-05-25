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

  // Same as in the contract, but checking e(S,G2) = e(m,P), not calculating H(m)
  function _verifyBlsSignature(
    bytes memory _message,
    bytes memory _signature,
    uint256[4] memory _publicKeyAggregated)
    public
    returns(bool)
    {
      // Get the coordinates of the signature aggreagetd
    bytes32 s1;
    bytes32 s2;
    assembly {
            s1 := mload(add(_signature, 0x20))
            s2 := mload(add(_signature, 0x40))
      }

    uint256[2] memory signature = BN256G1.fromCompressed(_signature);

     // Coordinates of the generator point of G2
    uint256 g2xx = uint256(0x198E9393920D483A7260BFB731FB5D25F1AA493335A9E71297E485B7AEF312C2);
    uint256 g2xy = uint256(0x1800DEEF121F1E76426A00665E5C4479674322D4F75EDADD46DEBD5CD992F6ED);
    uint256 g2yx = uint256(0x090689D0585FF075EC9E99AD690C3395BC4B313370B38EF355ACDADCD122975B);
    uint256 g2yy = uint256(0x12C85EA5DB8C6DEB4AAB71808DCB408FE3D1E7690C43D37B4CE6CC0166FA7DAA);


    // Coordinates of the message hash H(m)
    // uint256[2] memory hm;
    // (hm[0], hm[1]) = BN256G1.hashToTryAndIncrement(_message);
    bytes32 m1;
    bytes32 m2;
    assembly {
            m1 := mload(add(_message, 0x20))
            m2 := mload(add(_message, 0x40))
      }

    uint256[2] memory message = BN256G1.fromCompressed(_message);

    // uint256[12] memory input = [
    //   uint256(s1),
    //   uint256(s2),
    //   uint256(g2xx),
    //   uint256(g2xy),
    //   uint256(g2yx),
    //   uint256(g2yy),
    //   uint256(m1),
    //   uint256(m2),
    //   _publicKeyAggregated[0],
    //   _publicKeyAggregated[1],
    //   _publicKeyAggregated[2],
    //   _publicKeyAggregated[3]
    // ];

    uint256[12] memory input = [
      signature[0],
      signature[1],
      uint256(g2xx),
      uint256(g2xy),
      uint256(g2yx),
      uint256(g2yy),
      message[0],
      message[1],
      _publicKeyAggregated[0],
      _publicKeyAggregated[1],
      _publicKeyAggregated[2],
      _publicKeyAggregated[3]
    ];

    // Checks the pairing e(S,G2)= e(H(m), P)
    bool check = BN256G1.bn256CheckPairing(input);

    return check;
  }

  function _fromCompressed(bytes memory _point) public returns(uint256[2] memory) {
    uint256[2] memory s = BN256G1.fromCompressed(_point);
    return s;
  }

  // /// @dev aggregates the public keys to be used in BLS
  // /// @param _publicKeys Public Keys to be aggregated
  // function _publickeysAggregation(bytes[] memory _publicKeys)
  //   public
  //   returns(uint256[4] memory)
  // {
  //   uint256 n = _publicKeys.length;
  //   uint256[4] memory aggregatedPubKey;
  //   aggregatedPubKey = [
  //     pubKeyCoordinates[_publicKeys[0]].x1,
  //     pubKeyCoordinates[_publicKeys[0]].x2,
  //     pubKeyCoordinates[_publicKeys[0]].y1,
  //     pubKeyCoordinates[_publicKeys[0]].y2
  //   ];

  //   for (uint i = 1; i < n; i++) {
  //     aggregatedPubKey = BN256G2.ecTwistAdd(
  //        aggregatedPubKey[0],
  //        aggregatedPubKey[1],
  //        aggregatedPubKey[2],
  //        aggregatedPubKey[3],
  //        pubKeyCoordinates[_publicKeys[i]].x1,
  //        pubKeyCoordinates[_publicKeys[i]].x2,
  //        pubKeyCoordinates[_publicKeys[i]].y1,
  //        pubKeyCoordinates[_publicKeys[i]].y2
  //     );
  //     return aggregatedPubKey;
  //   }
  // }

  // function _proposeBlock(
  //   uint256 _blockHash,
  //   uint256 _epoch,
  //   uint256 _drMerkleRoot,
  //   uint256 _tallyMerkleRoot,
  //   uint256 _previousVote,
  //   uint256 _arsMerkleRoot,
  //   uint256[] memory _merklePath,
  //   bytes memory _aggregatedSig,
  //   uint256[4] memory _publicKeys
  // ) public
  // {
  //    // Define the vote
  //   uint256 vote = _blockHash;

  //   // 3. Verify the BLS signature with signature and public key aggregated
  //   require(
  //     verifyBlsSignature(
  //       abi.encode(vote),
  //       _aggregatedSig,
  //       _publicKeys
  //       ),
  //     "not valid BLS signature");

  //   // 4. Add vote information if it's a new vote
  //   if (voteInfo[vote].numberOfVotes == 0) {
  //     // Add the vote to candidates
  //     candidates.push(vote);
  //     // Mapping the vote into its hashes
  //     voteInfo[vote].voteHashes.blockHash = _blockHash;
  //     voteInfo[vote].voteHashes.drMerkleRoot = _drMerkleRoot;
  //     voteInfo[vote].voteHashes.tallyMerkleRoot = _tallyMerkleRoot;
  //     voteInfo[vote].voteHashes.previousVote = _previousVote;
  //     voteInfo[vote].voteHashes.epoch = _epoch;
  //   }

  //   // 5. Update the vote count
  //   updateVoteCount(vote, _publicKeys.length, 2**_merklePath.length);
  // }

}