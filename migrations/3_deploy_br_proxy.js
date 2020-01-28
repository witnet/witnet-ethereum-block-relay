var BlockRelayProxy = artifacts.require("BlockRelayProxy")
var BlockRelay = artifacts.require("BlockRelay")

module.exports = function (deployer, network) {
  console.log(`> Migrating BlockRelayProxy into ${network} network`)
  deployer.deploy(BlockRelayProxy, BlockRelay.address)  
}
