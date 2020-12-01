// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../contracts/ActiveBridgeSetBlockRelay.sol";


/**
 * @title Test Helper for the new block Relay contract
 * @dev The aim of this contract is to raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */
contract ABSBlockRelayTestHelper is ActiveBridgeSetBlockRelay {

  ActiveBridgeSetBlockRelay public br;
  uint256 public timestamp;

  constructor (
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock, address _wbiAddress)
  public
  ActiveBridgeSetBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock, _wbiAddress)  {}

  // Sets the current epoch to be the next
  function nextEpoch() external {
    currentEpoch = currentEpoch + 1;
  }

  // Sets the currentEpoch
  function setEpoch(uint256 _epoch) external {
    currentEpoch = _epoch;
  }

  // Gets the vote with the poposeBlock inputs
  function getVote(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote) external pure returns(uint256)
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
  function getBlockHash(uint256 _epoch) external  view returns (uint256) {
    uint256 blockHash = epochFinalizedBlock[_epoch];
    return blockHash;
  }

  // Gets the length of the candidates array
  function getCandidatesLength() external view returns (uint256) {
    return candidates.length;
  }

  // Checks if the epoch is finalized
  function checkEpochFinalized(uint256 _epoch) external view returns (bool) {
    if (epochFinalizedBlock[_epoch] != 0) {
      return true;
    }
  }

  // Updates the currentEpoch
  function updateEpoch() public view override returns (uint256) {
    return currentEpoch;
  }

}