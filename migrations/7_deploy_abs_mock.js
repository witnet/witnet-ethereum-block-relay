var ABSMock = artifacts.require("ABSMock")

module.exports = function (deployer, network) {
  console.log(`> Migrating ABSMock into ${network} network`)
  deployer.deploy(ABSMock)
}