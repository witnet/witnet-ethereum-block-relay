// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BlockRelayInterface.sol";


/**
 * @title Block relay contract
 * @notice Contract to store/read block headers from the Witnet network
 * @author Witnet Foundation
 */
contract CentralizedBlockRelay is BlockRelayInterface {

  // Block reporting is not subject to increases
  uint256 public constant MAX_REPORT_BLOCK_GAS = 127963;

  struct BlockInfo {
    // hash of the merkle root of the DRs in Witnet
    uint256 drHashMerkleRoot;
    // hash of the merkle root of the tallies in Witnet
    uint256 tallyHashMerkleRoot;
    // address of the relayer
    address relayerAddress;
    // flag to indicate that the relayer is paid
    bool isPaid;
  }
  

  struct Beacon {
    // hash of the last block
    uint256 blockHash;
    // epoch of the last block
    uint256 epoch;
  }
  
  // List of addresses authorized to post blocks
  address[] public committee;

  // Last block reported
  Beacon public lastBlock;

  mapping (uint256 => BlockInfo) public blocks;

  // Event emitted when a new block is posted to the contract
  event NewBlock(address indexed _from, uint256 _id);

  // Only the commitee defined when deploying the contract should be able to push blocks
  modifier isAuthorized() {
    bool senderAuthorized = false;
    for (uint256 i; i < committee.length; i++) {
      if (committee[i] == msg.sender) {
        senderAuthorized = true;   
      }       
    }
    require(senderAuthorized == true, "Sender not authorized");
    _; // Otherwise, it continues.
  }

  // Ensures block exists
  modifier blockExists(uint256 _id){
    require(blocks[_id].drHashMerkleRoot != 0, "Non-existing block");
    _;
  }

  // Ensures block does not exist
  modifier blockDoesNotExist(uint256 _id){
    require(blocks[_id].drHashMerkleRoot == 0, "The block already existed");
    _;
  }

  constructor(address[] memory _committee) public{
    // Only the contract deployer is able to push blocks
    committee = _committee;
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
  returns(bool)
  {
    uint256 drMerkleRoot = blocks[_blockHash].drHashMerkleRoot;
    return(_verifyPoi(
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
    return(_verifyPoi(
      _poi,
      tallyMerkleRoot,
      _index,
      _element));
  }

  /// @dev Verifies if the contract is upgradable
  /// @return true if the contract upgradable
  function isUpgradable(address _address) external view override returns(bool) {
    for (uint256 i; i < committee.length; i++) {
      if (committee[i] == _address) {
        return true;   
      }
    }
    return false;
  }

  /// @dev Post new block into the block relay
  /// @param _blockHash Hash of the block header
  /// @param _epoch Witnet epoch to which the block belongs to
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  function postNewBlock(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot)
    external
    isAuthorized
    blockDoesNotExist(_blockHash)
  {
    lastBlock.blockHash = _blockHash;
    lastBlock.epoch = _epoch;
    blocks[_blockHash].drHashMerkleRoot = _drMerkleRoot;
    blocks[_blockHash].tallyHashMerkleRoot = _tallyMerkleRoot;
    blocks[_blockHash].relayerAddress = msg.sender;
    emit NewBlock(msg.sender, _blockHash);
  }

  /// @dev Retrieve the requests-only merkle root hash that was reported for a specific block header.
  /// @param _blockHash Hash of the block header
  /// @return Requests-only merkle root hash in the block header.
  function readDrMerkleRoot(uint256 _blockHash)
    external
    view
    blockExists(_blockHash)
  returns(uint256)
  {
    return blocks[_blockHash].drHashMerkleRoot;
  }

  /// @dev Retrieve the tallies-only merkle root hash that was reported for a specific block header.
  /// @param _blockHash Hash of the block header.
  /// @return tallies-only merkle root hash in the block header.
  function readTallyMerkleRoot(uint256 _blockHash)
    external
    view
    blockExists(_blockHash)
  returns(uint256)
  {
    return blocks[_blockHash].tallyHashMerkleRoot;
  }

  /// @dev Retrieve address of the relayer that relayed a specific block header.
  /// @param _blockHash Hash of the block header.
  /// @return address of the relayer.
  function readRelayerAddress(uint256 _blockHash)
    external
    view
    override
    blockExists(_blockHash)
  returns(address)
  {
    return blocks[_blockHash].relayerAddress;
  }

  /// @dev Verifies the validity of a PoI
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _root the merkle root
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function _verifyPoi(
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
  /// @dev This function checks if the relayer has been paid
  /// @param _blockHash Hash of the block header
  /// @return true if the relayer has been paid, false otherwise
  function isRelayerPaid(uint256 _blockHash) internal returns(bool){
    return blocks[_blockHash].isPaid;
  }

  /// @dev Pay the block reward to the relayer in case it has not been paid before
  /// @param _blockHash Hash of the block header
  /// @return true if the relayer is paid, false otherwise
  function payRelayer(uint256 _blockHash) external payable returns(bool){
    if (isRelayerPaid(_blockHash) == false) {
      // Check if rewards are covering gas costs
      isPayingGasCosts(msg.value);

      blocks[_blockHash].isPaid == true;
      address payable relayer = payable(blocks[_blockHash].relayerAddress);
      relayer.transfer(msg.value);

      return true;
    } else {
      return false;
    }
  }

  /// @dev Estimate the amount of reward we need to insert for a given gas price
  /// @param _gasPrice The gas price for which we need to calculate the rewards
  /// @return The blockReward to be included for the given gas price
  function estimateGasCost(uint256 _gasPrice) public view returns(uint256){
    return SafeMath.mul(_gasPrice, MAX_REPORT_BLOCK_GAS);
  }

  /// @dev Ensures that rewards cover the cost of post a block in the Block Relay
  /// @param _blockReward The amount for rewarding the reporting of the blocks
  function isPayingGasCosts(uint256 _blockReward) internal view {
    uint256 minBlockReward =  estimateGasCost(tx.gasprice);
    require(_blockReward >= minBlockReward, "Block reward should cover gas expenses. Check the estimateGasCost method.");
  }

}
