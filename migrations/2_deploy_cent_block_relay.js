var CentralizedBlockRelay = artifacts.require("CentralizedBlockRelay")

module.exports = function (deployer, network) {
  console.log(`> Migrating CentralizedBlockRelay into ${network} network`)
  deployer.deploy(CentralizedBlockRelay)
}
