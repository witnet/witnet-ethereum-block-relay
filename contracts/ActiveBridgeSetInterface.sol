// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.6.0 <0.7.0;


/**
 * @title Active Bridge Set Interface
 * @notice Interface of Active Bridge Set methods
 * It defines how to interact with the ABS in order to support:
 *  - Check if an address is a ABS member
 *  - Get the number of members of the ABS
 * @author Witnet Foundation
 */
interface ActiveBridgeSetInterface {

  function absIsMember(address _address) external view returns (bool);

  function absCount() external view returns (uint32);

}