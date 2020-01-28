pragma solidity ^0.5.0;
import "./BlockRelayInterface.sol";

/**
 * @title Block Relay Proxy
 * @notice Contract to act as a proxy between the Witnet Bridge Interface and the block relay
 * @dev More information can be found here
 * DISCLAIMER: this is a work in progress, meaning the contract could be voulnerable to attacks
 * @author Witnet Foundation
 */


contract BlockRelayProxy {
  address public blockRelayAddress;
  address owner;
  BlockRelayInterface blockRelayInstance;

  modifier onlyOwner() {
    require(msg.sender == owner, "Permission denied");
    _;
  }

  modifier notIdentical(address _newAddress) {
    require(_newAddress != blockRelayAddress, "The Block Relay instance is already upgraded");
    _;
  }

  constructor(address _blockRelayAddress) public {
    // Only the contract deployer is able to change block relay controller
    owner = msg.sender;
    blockRelayAddress = _blockRelayAddress;
    blockRelayInstance = BlockRelayInterface(_blockRelayAddress);
  }

  /// @notice Returns the beacon from the last inserted block.
  /// The last beacon (in bytes) will be used by Witnet Bridge nodes to compute their eligibility.
  /// @return last beacon in bytes
  function getLastBeacon() external view returns(bytes memory) {
    return blockRelayInstance.getLastBeacon();
  }

  /// @notice Verifies the validity of a data request PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true if valid data request PoI
  function verifyDrPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element) external view returns(bool)
    {
    return blockRelayInstance.verifyDrPoi(
      _poi,
      _blockHash,
      _index,
      _element);
  }

  /// @notice Verifies the validity of a tally PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true if valid data request PoI
  function verifyTallyPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element) external view returns(bool)
    {
    return blockRelayInstance.verifyTallyPoi(
      _poi,
      _blockHash,
      _index,
      _element);
  }

  /// @notice Upgrades the block relay if valid
  /// @param _newAddress address of the new block relay to upgrade
  function upgradeBlockRelay(address _newAddress) public onlyOwner notIdentical(_newAddress) {
    require(blockRelayInstance.isUpgradable(), "The block relay is not upgradable");
    blockRelayAddress = _newAddress;
    blockRelayInstance = BlockRelayInterface(_newAddress);
  }

}
