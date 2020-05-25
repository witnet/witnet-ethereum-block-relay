const sha = require("js-sha256")
const ARSBlockRelayTestHelper = artifacts.require("ARSBlockRelayTestHelper")
const G1Library = artifacts.require("bls-solidity/BN256G1")
const G2Library = artifacts.require("bls-solidity/BN256G2")
//const ABSMock = artifacts.require("ActiveBridgeSetMock")
const truffleAssert = require("truffle-assertions")
contract("ARS Block Relay", accounts => {
  describe("ARS block relay test suite", () => {
    let blockRelay
     let libG1
     let libG2
    beforeEach(async () => {
      // libG1 = await G1Library.deployed()
      // libG2 = await G2Library.deployed()

      // await ARSBlockRelayTestHelper.link(G1Library, libG1.address)
      // await ARSBlockRelayTestHelper.link(G2Library, libG2.address)
      blockRelay = await ARSBlockRelayTestHelper.new(568559600, 90, 0, {
          from: accounts[0],
        })

      })
    

    it("should verify BLS signature", async () => {
       // it should verify the BLS signature
       // message signed
       const message = "0x73616d706c65"  
       // signature of H(message)
       const signature = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b" 
       // public key
       const pub_key = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
                        "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
                        "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
                        "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

      // Verify the signature  
      const pair = await blockRelay.verifyBlsSignature.call(message, signature, pub_key)
      assert.equal(pair, true)
  
    })

it("should aggregate public keys", async () => {
   // Decode the public key
   // public ley from secret key 0x2009da7287c158b126123c113d1c85241b6e3294dd75c643588630a8bc0f934c
   const comp_publickey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
  //  const pub_key_coordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
  //  "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
  //  "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
  //  "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

  const pub_key_coordinates1 = ["0x1d6b92aa7215a4a8cb4058046795f286ba64cf6d587da888ce4a174b83786796",
    "0x15afa104df881bb019cf06bc6e2751fd92d4d5e648ca79686cd3b7e282a99971",
   "0x0400ab98a6de8825ba644f7b593cacb1e30f46d42d7f28349dcc651499429cc8",
  "0x2519524f0d0953448e48fbaa1410ec7cd2b92746fcd1a91529a60de7d61ec09b"]


   // Public key form secret key 0x1ab1126ff2e37c6e6eddea943ccb3a48f83b380b856424ee552e113595525565
   const comp_publickey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
  //  const pub_key_coordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
  //            "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
  //            "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
  //            "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]
  
  const pub_key_coordinates2 = ["0x27c0a659e43c0be5c92fd146b10812933b5ada045703fe9cf822e5b8e5f425fa",
  "0x152f75c943ec0d7fc1a3b0936edb20fc6ca08ae27703140727d04e697185afda",
  "0x154eb77f49cac54f164d1a96ac47bc7b89076755846f84c87a8c12a7fbba6484",
  "0x219b10f5452d1e140ab88db9ede37dfd6c452214a9bc6a3eeac70afd42f3fcb8"]


  // decose broth public keys
  await blockRelay.decodePublicKeys(comp_publickey1, pub_key_coordinates1)
  await blockRelay.decodePublicKeys(comp_publickey2, pub_key_coordinates2)


  const aggre = await blockRelay.publickeysAggregation.call([comp_publickey1, comp_publickey2])
  const output =
    [ "0x19969e1b15ddc627fca32b1396d8b0b965dad62f63cc96da6e5a64c5a8c591aa",
    "0x1e97d007d9a26bfb87452dcb5fdccaaa43e6a9362ab2c6e4f619d45b53ba35b2",            
    "0x08e075836b61edb61c9f7c710c4c77fdb24d2e10b070307cd689c99fbfd147e5",
    "0x2cab5d238910cd06fa3f15d86d2597f9ddae6abc926f60e550be101c6c46f216"]

  assert.equal(aggre[0].toString(), web3.utils.toBN(output[0]).toString())
})


  //    it("should propose a Block", async () => {

  //     // The blockHash we want to propose
  //     const blockHash = "0x" + sha.sha256("sample")
  //     const epoch = 1
  //     const drMerkleRoot = 1
  //     const tallyMerkleRoot = 1
  //     const previousVote = 0

  //     const arsMerkleRoot = 1
  //     const arsMerklePath = 1

  //     const aggregatedSignatures = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
      
  //     const message = "0x73616d706c65"   
  //     const comp_signature = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"             
  //     //const signature = ["0x0xF047A153E94B5F109E4013D1BD078112817CF0D58CDF6BA8891F9849852BA5B", "0x0xC89855F1BD1C37BB2178B123FF337A0DF9DD1EAFB16A25E81EEEF477528BCDE"]
      

  //     const publicKey = ["0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2", "0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed", "0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b", "0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa"]

  //     const tx1 = await blockRelay._proposeBlock.call(blockHash, epoch, drMerkleRoot, tallyMerkleRoot, previousVote, arsMerkleRoot, arsMerklePath, aggregatedSignatures, publicKey)

  //     //const message = "0x73616d706c65"
  //     // const pair = await blockRelay._verifyBlsSignature(message, comp_signature, publicKey)

  //  //    const pair = await blockRelay._verifyBlsSignature.call([
  //  //     web3.utils.toBN(test.input.x1_g1),
  //  //     web3.utils.toBN(test.input.y1_g1),
  //  //     web3.utils.toBN(test.input.x1_re_g2),
  //  //     web3.utils.toBN(test.input.x1_im_g2),
  //  //     web3.utils.toBN(test.input.y1_re_g2),
  //  //     web3.utils.toBN(test.input.y1_im_g2),
  //  //     web3.utils.toBN(test.input.x2_g1),
  //  //     web3.utils.toBN(test.input.y2_g1),
  //  //     web3.utils.toBN(test.input.x2_re_g2),
  //  //     web3.utils.toBN(test.input.x2_im_g2),
  //  //     web3.utils.toBN(test.input.y2_re_g2),
  //  //     web3.utils.toBN(test.input.y2_im_g2)])
  //  //   assert.equal(pair, test.output.success)
  //   })

})
})


const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
