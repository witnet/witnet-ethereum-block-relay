pragma solidity 0.6.4;

import "../../contracts/ActiveBridgeSetBlockRelay.sol";


/**
 * @title Test Helper for the new block Relay contract
 * @dev The aim of this contract is to raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */
contract ABSBlockRelayTestHelper is ActiveBridgeSetBlockRelay {

  ActiveBridgeSetBlockRelay br;
  uint256 timestamp;


  constructor (
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock, address _wbiAddress)
  ActiveBridgeSetBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock, _wbiAddress) public {}

  // Updates the currentEpoch
  function updateEpoch() public view override returns (uint256) {
    return currentEpoch;
  }

  // Sets the current epoch to be the next
  function nextEpoch() public {
    currentEpoch = currentEpoch + 1;
  }

  // Sets the currentEpoch
  function setEpoch(uint256 _epoch) public returns (uint256) {
    currentEpoch = _epoch;
  }

  // Gets the vote with the poposeBlock inputs
  function getVote(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote) public pure returns(uint256)
    {
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));

    return vote;

  }

  // Gets the blockHash of a vote finalized in a specific epoch
  function getBlockHash(uint256 _epoch) public  view returns (uint256) {
    uint256 blockHash = epochFinalizedBlock[_epoch];
    return blockHash;
  }

  // Gets the length of the candidates array
  function getCandidatesLength() public view returns (uint256) {
    return candidates.length;
  }

  // Checks if the epoch is finalized
  function checkEpochFinalized(uint256 _epoch) public view returns (bool) {
    if (epochFinalizedBlock[_epoch] != 0) {
      return true;
    }
  }

}