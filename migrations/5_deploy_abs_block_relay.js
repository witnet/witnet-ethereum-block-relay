var ABSBlockRelay = artifacts.require("ABSBlockRelay")
var WitnetBridgeInterface = artifacts.require("WitnetBridgeInterface")

module.exports = function (deployer, network) {
  console.log(`> Migrating ABSBlockRelay into ${network} network`)
  deployer.deploy(ABSBlockRelay, 1568559600, 90, 0, WitnetBridgeInterface.address)
}