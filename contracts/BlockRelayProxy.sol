pragma solidity 0.6.4;

import "./BlockRelayInterface.sol";


/**
 * @title Block Relay Proxy
 * @notice Contract to act as a proxy between the Witnet Bridge Interface and the block relay
 * @dev More information can be found here
 * DISCLAIMER: this is a work in progress, meaning the contract could be voulnerable to attacks
 * @author Witnet Foundation
 */
contract BlockRelayProxy {

  // Address of the current controller
  address internal blockRelayAddress;
  // Current interface to the controller
  BlockRelayInterface internal blockRelayInstance;

  struct ControllerInfo {
    // last epoch seen by a controller
    uint256 lastEpoch;
    // address of the controller
    address blockRelayController;
  }

  // array containing the information about controllers
  ControllerInfo[] internal controllers;

  modifier notIdentical(address _newAddress) {
    require(_newAddress != blockRelayAddress, "The provided Block Relay instance address is already in use");
    _;
  }

  constructor(address _blockRelayAddress) public {
    // Initialize the first epoch pointing to the first controller
    controllers.push(ControllerInfo({lastEpoch: 0, blockRelayController: _blockRelayAddress}));
    blockRelayAddress = _blockRelayAddress;
    blockRelayInstance = BlockRelayInterface(_blockRelayAddress);
  }

  /// @notice Returns the beacon from the last inserted block.
  /// The last beacon (in bytes) will be used by Witnet Bridge nodes to compute their eligibility.
  /// @return last beacon in bytes
  function getLastBeacon() external view returns(bytes memory) {
    return blockRelayInstance.getLastBeacon();
  }

  /// @notice Returns the last Wtinet epoch known to the block relay instance.
  /// @return The last epoch is used in the WRB to avoid reusage of PoI in a data request.
  function getLastEpoch() external view returns(uint256) {
    return blockRelayInstance.getLastEpoch();
  }

  /// @notice Verifies the validity of a data request PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _epoch the epoch of the blockchash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true if valid data request PoI
  function verifyDrPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _index,
    uint256 _element) external view returns(bool)
    {
    address controller = getController(_epoch);
    return BlockRelayInterface(controller).verifyDrPoi(
      _poi,
      _blockHash,
      _index,
      _element);
  }

  /// @notice Verifies the validity of a tally PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _epoch the epoch of the blockchash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true if valid data request PoI
  function verifyTallyPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _index,
    uint256 _element) external view returns(bool)
    {
    address controller = getController(_epoch);

    return BlockRelayInterface(controller).verifyTallyPoi(
      _poi,
      _blockHash,
      _index,
      _element);
  }

  /// @notice Upgrades the block relay if the current one is upgradeable
  /// @param _newAddress address of the new block relay to upgrade
  function upgradeBlockRelay(address _newAddress) external notIdentical(_newAddress) {
    // Check if the controller is upgradeable
    require(blockRelayInstance.isUpgradable(msg.sender), "The upgrade has been rejected by the current implementation");
    // Get last epoch seen by the replaced controller
    uint256 epoch = blockRelayInstance.getLastEpoch();
    // Get the length of last epochs seen by the different controllers
    uint256 n = controllers.length;
    // If the the last epoch seen by the replaced controller is lower than the one already anotated e.g. 0
    // just update the already anotated epoch with the new address, ignoring the previously inserted controller
    // Else, anotate the epoch from which the new controller should start receiving blocks
    if (epoch < controllers[n-1].lastEpoch) {
      controllers[n-1].blockRelayController = _newAddress;
    } else {
      controllers.push(ControllerInfo({lastEpoch: epoch+1, blockRelayController: _newAddress}));
    }

    // Update instance
    blockRelayAddress = _newAddress;
    blockRelayInstance = BlockRelayInterface(_newAddress);
  }

  /// @notice Gets the controller associated with the BR controller corresponding to the epoch provided
  /// @param _epoch the epoch to work with
  function getController(uint256 _epoch) public view returns(address _controller) {
    // Get length of all last epochs seen by controllers
    uint256 n = controllers.length;
    // Go backwards until we find the controller having that blockhash
    for (uint i = n; i > 0; i--) {
      if (_epoch >= controllers[i-1].lastEpoch) {
        return (controllers[i-1].blockRelayController);
      }
    }
  }
}
