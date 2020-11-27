const truffleAssert = require("truffle-assertions")
const BlockRelayV1 = artifacts.require("TestBlockRelayV1")
const BlockRelayProxy = artifacts.require("BlockRelayProxy")
const BlockRelayV2 = artifacts.require("TestBlockRelayV2")
const BlockRelayV3 = artifacts.require("TestBlockRelayV3")
const BlockRelayV4 = artifacts.require("TestBlockRelayV4")

contract("Block relay Interface", accounts => {
  describe("Block relay Interface test suite", () => {
    let blockRelayInstance1
    let blockRelayInstance2
    let blockRelayInstance3
    let blockRelayInstance4
    let blockRelayProxy

    before(async () => {
      blockRelayInstance1 = await BlockRelayV1.new({
        from: accounts[0],
      })
      blockRelayInstance2 = await BlockRelayV2.new({
        from: accounts[0],
      })
      blockRelayInstance3 = await BlockRelayV3.new({
        from: accounts[0],
      })
      blockRelayInstance4 = await BlockRelayV4.new({
        from: accounts[0],
      })
      blockRelayProxy = await BlockRelayProxy.new(blockRelayInstance1.address, {
        from: accounts[0],
      })
    })

    it("should revert when trying to verify dr in blockRelayInstance", async () => {
      // It should revert because of the blockExists modifer in blockRelayInstance
      await truffleAssert.reverts(blockRelayProxy.verifyDrPoi([1], 11, 1, 1, 1), "Non-existing block")
    })

    it("should return the first controllerwhen checking for 0", async () => {
      const controller = await blockRelayProxy.getController(0)
      assert.equal(controller, blockRelayInstance1.address)
    })

    it("should return true when block is inserted", async () => {
      await blockRelayInstance1.postNewBlock(11, 1, 1, 1)
      // It should revert because of the blockExists modifer in blockRelayInstance
      assert.equal(await blockRelayProxy.verifyDrPoi([1], 11, 1, 1, 1), true)
      const controller = await blockRelayProxy.getController(1)
      assert.equal(controller, blockRelayInstance1.address)
    })

    it("should change the BR instance and be able to read verify dr poi", async () => {
      // it should not revert because the block relay has changed and the modifier in no longer needed
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance2.address, {
        from: accounts[0],
      })

      await blockRelayInstance2.postNewBlock(12, 2, 1, 1)
      await blockRelayInstance2.postNewBlock(13, 3, 1, 1)
      await blockRelayInstance2.postNewBlock(14, 4, 1, 1)
      let controller = await blockRelayProxy.getController(1)
      assert.equal(controller, blockRelayInstance1.address)
      controller = await blockRelayProxy.getController(2)
      assert.equal(controller, blockRelayInstance2.address)
      const dr = await blockRelayProxy.verifyDrPoi([1], 11, 1, 1, 1)
      assert.equal(dr, true)
      const dr2 = await blockRelayProxy.verifyDrPoi([1], 12, 2, 1, 1)
      assert.equal(dr2, false)
    })

    it("should change the return value when upgrading the BR", async () => {
      // it should return diffrent values when changing the BR
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance3.address, {
        from: accounts[0],
      })
      // Lets test the controllers first
      let controller = await blockRelayProxy.getController(1)
      assert.equal(controller, blockRelayInstance1.address)
      controller = await blockRelayProxy.getController(4)
      assert.equal(controller, blockRelayInstance2.address)
      controller = await blockRelayProxy.getController(5)
      assert.equal(controller, blockRelayInstance3.address)

      // We are asking for the first id so it should output still true
      const dr = await blockRelayProxy.verifyTallyPoi([1], 11, 1, 1, 1)
      assert.equal(dr, true)

      // We are asking for the fourth id so it should output still true
      const dr4 = await blockRelayProxy.verifyTallyPoi([1], 14, 4, 1, 1)
      assert.equal(dr4, true)

      // We are asking for the fith id so it should output false
      const dr5 = await blockRelayProxy.verifyTallyPoi([1], 15, 5, 1, 1)
      assert.equal(dr5, false)
    })

    it("should update the controller if no one inserted blocks for the ", async () => {
      let controller = await blockRelayProxy.getController(5)
      assert.equal(controller, blockRelayInstance3.address)
      // Upgrade block relay instance 4
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance4.address, {
        from: accounts[0],
      })

      controller = await blockRelayProxy.getController(5)
      assert.equal(controller, blockRelayInstance4.address)
    })

    it("should revert when upgrading the same address", async () => {
      // It should not allow upgrading the BR if presenting the current address
      await truffleAssert.reverts(blockRelayProxy.upgradeBlockRelay(blockRelayInstance4.address, {
        from: accounts[0],
      }), "The provided Block Relay instance address is already in use")
    })

    it("should revert when upgrading a non upgradable block relay", async () => {
      // It should revert since block relay instance 4 is not upgradable
      await truffleAssert.reverts(blockRelayProxy.upgradeBlockRelay(blockRelayInstance3.address, {
        from: accounts[0],
      }), "The upgrade has been rejected by the current implementation")
    })
  })
})
