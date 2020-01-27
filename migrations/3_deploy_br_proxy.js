var BlockRelayProxy = artifacts.require("BlockRelayProxy")

module.exports = function (deployer, network) {
  console.log(`> Migrating BlockRelayProxy into ${network} network`)
  deployer.deploy(BlockRelayProxy)
}
