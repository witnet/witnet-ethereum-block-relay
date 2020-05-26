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

      const signature_coordinates = await blockRelay._fromCompressed.call(signature)

      const pair2 = await blockRelay._verifyBlsSignature.call(message, [signature_coordinates[0], signature_coordinates[1]], pub_key)
      assert.equal(pair2, true)
  
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
  assert.equal(aggre[1].toString(), web3.utils.toBN(output[1]).toString())
  assert.equal(aggre[2].toString(), web3.utils.toBN(output[2]).toString())
  assert.equal(aggre[3].toString(), web3.utils.toBN(output[3]).toString())
})


it("should propose a block", async () => {
  // Decode the public key
  // public ley from secret key 0x2009da7287c158b126123c113d1c85241b6e3294dd75c643588630a8bc0f934c
  const comp_publickey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
  const pub_key_coordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
  "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
  "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
  "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

  // Public key form secret key 0x1ab1126ff2e37c6e6eddea943ccb3a48f83b380b856424ee552e113595525565
  const comp_publickey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
   const pub_key_coordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
             "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
             "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
             "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]

  // decose broth public keys
  await blockRelay.decodePublicKeys(comp_publickey1, pub_key_coordinates1)
  await blockRelay.decodePublicKeys(comp_publickey2, pub_key_coordinates2)

  const pubKeys = [comp_publickey1, comp_publickey2]

  const aggre = await blockRelay.publickeysAggregation.call([comp_publickey1, comp_publickey2])
  

  // The blockHash we want to propose
  const blockHash = "0x73616d706c65"
  const epoch = 1
  const drMerkleRoot = 1
  const tallyMerkleRoot = 1
  const previousVote = 0

  const arsMerkleRoot = 1
  const arsMerklePath = 1


  // Signature1 of blocHash
  const signature1 = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
   // Signature2 of blocHash
  const signature2 = "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"

  const coord_sig1 = await blockRelay._fromCompressed.call(signature1)
  const coord_sig2 = await blockRelay._fromCompressed.call(signature2)

  const aggregated_sig =  await blockRelay._aggregateSignature.call([coord_sig1[0], coord_sig1[1], coord_sig2[0], coord_sig2[1]])
  console.log(aggregated_sig[0].toString())
  console.log(aggregated_sig[1].toString())
  
  const signatureAgg = ["0x10242B541D26E0EAF9996467281ACB2B0294FD7CFF3631B5FAAEB5AC1D3741F7",
  "0x22C6857A2F1068862313132914E4CAB33B352B8A79CBD65E71D5FBB5316EFFDC"]

const proposeVote = await blockRelay._proposeBlock.call(blockHash, blockHash, epoch, drMerkleRoot, tallyMerkleRoot, previousVote, arsMerkleRoot, [arsMerklePath], signatureAgg, pubKeys)

})

it("should verify BLS signature aggregated", async () => {
       // it should verify the BLS signature
       // message signed
       const message = "0x73616d706c65"

        // Signature1 of blocHash from secret key 2009da7287c158b126123c113d1c85241b6e3294dd75c643588630a8bc0f934c
  const signature1 = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
   // Signature2 of blocHash from secret key 1ab1126ff2e37c6e6eddea943ccb3a48f83b380b856424ee552e113595525565
  const signature2 = "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"

  const coord_sig1 = await blockRelay._fromCompressed.call(signature1)
  const coord_sig2 = await blockRelay._fromCompressed.call(signature2)
  const agg_sig = await blockRelay._aggregateSignature.call([coord_sig1[0], coord_sig1[1], coord_sig2[0], coord_sig2[1]])
       // signature of H(message)
       const signatureAgg_comp = "0x02030644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3" 

       const signatureAgg = ["0x030644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3",
       "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"]
       // public key

       const comp_publickey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
  const pub_key_coordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
  "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
  "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
  "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

        const comp_publickey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
       const pub_key_coordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
             "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
             "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
             "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]

  // decose broth public keys
  await blockRelay.decodePublicKeys(comp_publickey1, pub_key_coordinates1)
  await blockRelay.decodePublicKeys(comp_publickey2, pub_key_coordinates2)

  const aggregated_pubKey = await blockRelay.publickeysAggregation.call([comp_publickey1, comp_publickey2])

      // Verify the signature  
       const pair = await blockRelay._verifyBlsSignature.call(message, [agg_sig[0], agg_sig[1]], [aggregated_pubKey[0], aggregated_pubKey[1], aggregated_pubKey[2], aggregated_pubKey[3]])
       assert.equal(pair, true)
  
  
    })

    it("should verify BLS signature1", async () => {
       // it should verify the BLS signature
       // message signed
       const message = "0x73616d706c65"

        // Signature1 of blocHash
  const signature1 = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
   
  const coord_sig1 = await blockRelay._fromCompressed.call(signature1)


  const comp_publickey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
  const pub_key_coordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
  "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
  "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
  "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

  // decose broth public keys
  await blockRelay.decodePublicKeys(comp_publickey1, pub_key_coordinates1)


      // Verify the signature  
      // const pair = await blockRelay._verifyBlsSignature.call(message, [signatureAgg[0], signatureAgg[1]], [output[0], output[1], output[2], output[3]])
      // assert.equal(pair, true)
      //const pair = await blockRelay._verifyBlsSignature.call(message, [coord_sig1[0], coord_sig1[1]], [pub_key_coordinates1[0], pub_key_coordinates1[1], pub_key_coordinates1[2], pub_key_coordinates1[3]])
      //assert.equal(pair, true)
      const pair = await blockRelay.verifyBlsSignature.call(message, signature1, [pub_key_coordinates1[0], pub_key_coordinates1[1], pub_key_coordinates1[2], pub_key_coordinates1[3]])
      assert.equal(pair, true)
      const pair2 = await blockRelay._verifyBlsSignature.call(message, [coord_sig1[0], coord_sig1[1]],  [pub_key_coordinates1[0], pub_key_coordinates1[1], pub_key_coordinates1[2], pub_key_coordinates1[3]])
      assert.equal(pair2, true)
  
  
    })

    it("should verify BLS signature2", async () => {
       // it should verify the BLS signature
       // message signed
       const message = "0x73616d706c65"
   // Signature2 of blocHash
  const signature2 = "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"

  const coord_sig2 = await blockRelay._fromCompressed.call(signature2)

        const comp_publickey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
       const pub_key_coordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
             "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
             "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
             "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]
await blockRelay.decodePublicKeys(comp_publickey2, pub_key_coordinates2)

      // Verify the signature  
      // const pair = await blockRelay._verifyBlsSignature.call(message, [signatureAgg[0], signatureAgg[1]], [output[0], output[1], output[2], output[3]])
      // assert.equal(pair, true)
      //const pair = await blockRelay._verifyBlsSignature.call(message, [coord_sig1[0], coord_sig1[1]], [pub_key_coordinates1[0], pub_key_coordinates1[1], pub_key_coordinates1[2], pub_key_coordinates1[3]])
      //assert.equal(pair, true)
      const pair = await blockRelay.verifyBlsSignature.call(message, signature2, [pub_key_coordinates2[0], pub_key_coordinates2[1], pub_key_coordinates2[2], pub_key_coordinates2[3]])
      assert.equal(pair, true)
      const pair2 = await blockRelay._verifyBlsSignature.call(message, [coord_sig2[0], coord_sig2[1]],  [pub_key_coordinates2[0], pub_key_coordinates2[1], pub_key_coordinates2[2], pub_key_coordinates2[3]])
      assert.equal(pair2, true)
  
  
    })



})
})


const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
