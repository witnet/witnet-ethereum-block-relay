const sha = require("js-sha256")
const ABSBlockRelayTestHelper = artifacts.require("ABSBlockRelayTestHelper")
const ABSMock = artifacts.require("ActiveBridgeSetMock")
const truffleAssert = require("truffle-assertions")
contract("ABS Block Relay", accounts => {
  describe("ABS block relay test suite", () => {
    let contest
    let abs
    beforeEach(async () => {
      abs = await ABSMock.new({
        from: accounts[0],
      })

      contest = await ABSBlockRelayTestHelper.new(1568559600, 90, 0, abs.address, {
        from: accounts[0],
      })
    })
    it("should propose and post a new block", async () => {
      // The blockHash we want to propose
      const blockHash = "0x" + sha.sha256("the vote to propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1

      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      let epoch = await contest.updateEpoch.call()

      // Update the ABS to be included
      await abs.pushActivity({
        from: accounts[0],
      })
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(blockHash, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0, {
        from: accounts[0],
      })
      await waitForHash(tx)
      // Get the vote proposed as the concatenation of the inputs of the proposeBlock
      const Vote = await contest.getVote.call(blockHash, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)

      // Wait unitl the next epoch to get the final result
      await contest.nextEpoch()
      epoch = await contest.updateEpoch.call()

      // Propose another block in the next epoch so the previous one is finalized
      await contest.proposeBlock(0, epoch - 1, 0, 0, Vote, {
        from: accounts[0],
      })

      // Concatenation of the blockHash and the epoch-1 to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(blockHash).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 2), 64
          )
        )
      )
      // Get last beacon
      const beacon = await contest.getLastBeacon.call()

      // Should be equal the last beacon to vote
      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })

  })
})
const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
