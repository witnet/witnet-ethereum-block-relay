pragma solidity 0.6.4;

import "../../contracts/ActiveReputationSetBlockRelay.sol";


/**
 * @title Test Helper for the new block Relay contract
 * @dev The aim of this contract is to raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */
contract ARSBlockRelayTestHelper is ActiveReputationSetBlockRelay {

  ActiveReputationSetBlockRelay public br;
  uint256 public timestamp;

  constructor (
    uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock, address _wrbAddress)
  ActiveReputationSetBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock, _wrbAddress) public {}



}