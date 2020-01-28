var BlockRelayProxy = artifacts.require("BlockRelayProxy")
var BlockRelayController = artifacts.require("ABSBlockRelay")

module.exports = async (deployer, network) => {
    console.log(`> Setting BlockRelayController`)
    var proxy = await BlockRelayProxy.deployed()
    await proxy.upgradeBlockRelay(BlockRelayController.address)
  }