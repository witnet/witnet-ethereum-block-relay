pragma solidity ^0.5.0;
/**
 * @title Active Bridge Set Witnet Requests Board
 * @notice Interface of a Witnet Requests Board with ABS methods
 * It defines how to interact with the Block Relay in order to support:
 *  - Check if an address is a ABS member
 *  - Get the number of members of the ABS
 * @author Witnet Foundation
 */
interface ABSWitnetRequestsBoardInterface {

  function isABSMember(address _address) external view returns (bool);

  function absCount() external view returns (uint32);

}