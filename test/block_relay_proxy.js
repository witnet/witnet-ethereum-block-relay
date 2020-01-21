const BlockRelay = artifacts.require("TestBlockRelay")
const truffleAssert = require("truffle-assertions")
const BlockRelayProxy = artifacts.require("BlockRelayProxy")
const BlockRelayV2 = artifacts.require("TestBlockRelayV2")
const BlockRelayV3 = artifacts.require("TestBlockRelayV3")

contract("Block relay Interface", accounts => {
  describe("Block relay Interface test suite", () => {
    let blockRelayInstance
    let blockRelayInstance2
    let blockRelayInstance3
    let blockRelayProxy

    before(async () => {
      blockRelayInstance = await BlockRelay.new({
        from: accounts[0],
      })
      blockRelayInstance2 = await BlockRelayV2.new({
        from: accounts[0],
      })
      blockRelayInstance3 = await BlockRelayV3.new({
        from: accounts[0],
      })

      blockRelayProxy = await BlockRelayProxy.new({
        from: accounts[0],
      })
      await blockRelayProxy.UpgradeBlockRelay(blockRelayInstance.address, {
        from: accounts[0],
      })
    })
    it("should revert when trying to verify dr in instance 1", async () => {
      await truffleAssert.reverts(blockRelayProxy.verifyDrPoi([1], 1, 1, 1), "Non-existing block")
    })
    it("should change the BR instance and be able to read verify dr poi", async () => {
      await blockRelayProxy.UpgradeBlockRelay(blockRelayInstance2.address, {
        from: accounts[0],
      })
      const dr = await blockRelayProxy.verifyDrPoi([1], 1, 1, 1)
      assert.equal(dr, true)
    })

    it("should revert when upgrading the same address", async () => {
      await truffleAssert.reverts(blockRelayProxy.UpgradeBlockRelay(blockRelayInstance2.address, {
        from: accounts[0],
      }), "The Block Relay instance is already upgraded")
    })

    it("should revert when trying to upgrade with non-owner", async () => {
      await truffleAssert.reverts(blockRelayProxy.UpgradeBlockRelay(blockRelayInstance.address, {
        from: accounts[1],
      }), "Permission denied")
    })
  })
})
