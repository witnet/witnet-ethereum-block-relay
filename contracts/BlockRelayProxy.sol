pragma solidity ^0.5.0;
import "./BlockRelayInterface.sol";

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
  constructor() public{
    // Only the contract deployer is able to push blocks
    owner = msg.sender;
  }

  function UpgradeBlockRelay(address _newAddress) public onlyOwner notIdentical(_newAddress) {
    blockRelayAddress = _newAddress;
    blockRelayInstance = BlockRelayInterface(_newAddress);
  }

  /// @notice Returns the beacon from the last inserted block.
  /// The last beacon (in bytes) will be used by Witnet Bridge nodes to compute their eligibility.
  /// @return last beacon in bytes
  function getLastBeacon() external view returns(bytes memory){
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
    uint256 _element) external view returns(bool){
      return blockRelayInstance.verifyDrPoi(_poi, _blockHash,_index, _element);

    }

  function verifyTallyPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element) external view returns(bool){
     return blockRelayInstance.verifyTallyPoi(_poi, _blockHash,_index, _element);
    }
}
