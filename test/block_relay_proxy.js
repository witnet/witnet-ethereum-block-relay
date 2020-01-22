const BlockRelayV1 = artifacts.require("TestBlockRelayV1")
const truffleAssert = require("truffle-assertions")
const BlockRelayProxy = artifacts.require("BlockRelayProxy")
const BlockRelayV2 = artifacts.require("TestBlockRelayV2")
const BlockRelayV3 = artifacts.require("TestBlockRelayV3")

contract("Block relay Interface", accounts => {
  describe("Block relay Interface test suite", () => {
    let blockRelayInstance1
    let blockRelayInstance2
    let blockRelayInstance3
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
      blockRelayProxy = await BlockRelayProxy.new({
        from: accounts[0],
      })
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance1.address, {
        from: accounts[0],
      })
    })
    it("should revert when trying to verify dr in blockRelayInstance", async () => {
      // It should revert because of the blockExists modifer in blockRelayInstance
      await truffleAssert.reverts(blockRelayProxy.verifyDrPoi([1], 1, 1, 1), "Non-existing block")
    })

    it("should change the BR instance and be able to read verify dr poi", async () => {
      // it should not revert because the block relay has changed and the modifier in no longer needed
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance2.address, {
        from: accounts[0],
      })

      const dr = await blockRelayProxy.verifyDrPoi([1], 1, 1, 1)
      assert.equal(dr, true)
    })

    it("should change the return value when upgrading the BR", async () => {
      // it should return diffrent values when changing the BR
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance3.address, {
        from: accounts[0],
      })
      const dr = await blockRelayProxy.verifyTallyPoi([1], 1, 1, 1)
      assert.equal(dr, false)
      // it should not revert because the block relay has changed and the modifier in no longer needed
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance2.address, {
        from: accounts[0],
      })
      const dr2 = await blockRelayProxy.verifyTallyPoi([1], 1, 1, 1)
      assert.equal(dr2, true)
    })

    it("should revert when upgrading the same address", async () => {
      // It should not allow upgrading the BR if presenting the current address
      await truffleAssert.reverts(blockRelayProxy.upgradeBlockRelay(blockRelayInstance2.address, {
        from: accounts[0],
      }), "The Block Relay instance is already upgraded")
    })

    it("should revert when trying to upgrade with non-owner", async () => {
      // It should not allow upgrading the BR becouse of the onlyOwner modifier
      await truffleAssert.reverts(blockRelayProxy.upgradeBlockRelay(blockRelayInstance1.address, {
        from: accounts[1],
      }), "Permission denied")
    })

    /* it("should not allow ", async () => {
      // It should not allow upgrading the BR becouse of the onlyOwner modifier
      await blockRelayProxy.upgradeBlockRelay(blockRelayInstance3.address, {
        from: accounts[0],
      })
      await truffleAssert.reverts(blockRelayProxy.getLastBecon());

    }) */
  })
})
