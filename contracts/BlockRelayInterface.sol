// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;


/**
 * @title Block Relay Interface
 * @notice Interface of a Block Relay to a Witnet network
 * It defines how to interact with the Block Relay in order to support:
 *  - Retrieve last beacon information
 *  - Verify proof of inclusions (PoIs) of data request and tally transactions
 * @author Witnet Foundation
 */
interface BlockRelayInterface {

  /// @dev Pays the block reward to the relayer in case it has not been paid before
  /// @param _blockHash Hash of the block header
  function payRelayer(uint256 _blockHash) external payable;

  /// @notice Returns the beacon from the last inserted block.
  /// The last beacon (in bytes) will be used by Witnet Bridge nodes to compute their eligibility.
  /// @return last beacon in bytes
  function getLastBeacon() external view returns(bytes memory);

  /// @notice Returns the lastest epoch reported to the block relay.
  /// @return epoch
  function getLastEpoch() external view returns(uint256);

  /// @notice Returns the latest hash reported to the block relay
  /// @return blockhash
  function getLastHash() external view returns(uint256);

  /// @dev Checks if the relayer has been paid
  /// @param _blockHash Hash of the block header
  /// @return true if the relayer has been paid, false otherwise
  function isRelayerPaid(uint256 _blockHash) external view returns(bool);

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
    uint256 _element) external view returns(bool);

  /// @notice Verifies the validity of a tally PoI against the Tally merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true if valid tally PoI
  function verifyTallyPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element) external view returns(bool);

  /// @notice Verifies if the block relay can be upgraded
  /// @return true if contract is upgradable
  function isUpgradable(address _address) external view returns(bool);

  /// @dev Retrieves address of the relayer that relayed a specific block header.
  /// @param _blockHash Hash of the block header.
  /// @return address of the relayer.
  function readRelayerAddress(uint256 _blockHash)
    external
    view
  returns(address);
}