var CentralizedBlockRelay = artifacts.require("CentralizedBlockRelay")

module.exports = function (deployer, network, accounts) {
  console.log(`> Migrating CentralizedBlockRelay into ${network} network`)
  deployer.deploy(CentralizedBlockRelay, [accounts[0]])
}
