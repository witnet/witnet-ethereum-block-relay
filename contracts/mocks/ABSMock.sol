pragma solidity ^0.5.0;

import "../ABSInterface.sol";

/**
 * @title Mock of the wbi to get the ABS interface methods
 * @dev The aim of this contract is to mock the ABS methods for testing purposes
 * @author Witnet Foundation
 */


contract ABSMock is ABSInterface {

  mapping(address => bool) fakeABS;

  uint32 count;

  function isABSMember(address _address) external view returns (bool) {
    return fakeABS[_address];
  }

  // Pushes the activity in the ABS
  function pushActivity() external {
    address _address = msg.sender;
    if (fakeABS[_address] == false) {
      count++;
      fakeABS[_address] = true;
    }
  }

    // Gets the number of active identities in the ABS
  function absCount() external view returns (uint32) {
    return count;
  }

  // Sets the number of members in the ABS
  function setAbsIdentitiesNumber(uint32 _identitiesNumber) external returns (uint256) {
    count = _identitiesNumber;
  }






}
