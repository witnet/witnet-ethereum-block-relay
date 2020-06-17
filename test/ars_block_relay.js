const ARSBlockRelayTestHelper = artifacts.require("ARSBlockRelayTestHelper")
contract("ARS Block Relay", accounts => {
  describe("ARS block relay test suite", () => {
    let blockRelay
    beforeEach(async () => {
      blockRelay = await ARSBlockRelayTestHelper.new(568559600, 90, 0, {
        from: accounts[0],
      })
    })

    it("should aggregate public keys", async () => {
      // public key from secret key 0x2009da7287c158b126123c113d1c85241b6e3294dd75c643588630a8bc0f934c
      const refPublickey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
      const pubKeyCoordinates1 = ["0x1d6b92aa7215a4a8cb4058046795f286ba64cf6d587da888ce4a174b83786796",
        "0x15afa104df881bb019cf06bc6e2751fd92d4d5e648ca79686cd3b7e282a99971",
        "0x0400ab98a6de8825ba644f7b593cacb1e30f46d42d7f28349dcc651499429cc8",
        "0x2519524f0d0953448e48fbaa1410ec7cd2b92746fcd1a91529a60de7d61ec09b"]

      // public key from secret key 0x1ab1126ff2e37c6e6eddea943ccb3a48f83b380b856424ee552e113595525565
      const refPublickey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
      const pubKeyCoordinates2 = ["0x27c0a659e43c0be5c92fd146b10812933b5ada045703fe9cf822e5b8e5f425fa",
        "0x152f75c943ec0d7fc1a3b0936edb20fc6ca08ae27703140727d04e697185afda",
        "0x154eb77f49cac54f164d1a96ac47bc7b89076755846f84c87a8c12a7fbba6484",
        "0x219b10f5452d1e140ab88db9ede37dfd6c452214a9bc6a3eeac70afd42f3fcb8"]

      // store the coordinates corresponding to each public key reference
      await blockRelay.storeCoordinatesPublicKeys(refPublickey1, pubKeyCoordinates1)
      await blockRelay.storeCoordinatesPublicKeys(refPublickey2, pubKeyCoordinates2)

      // aggregate the public keys
      const aggregatedPubKeys = await blockRelay.publickeysAggregation.call([refPublickey1, refPublickey2])
      // expected result
      const expected = ["0x19969e1b15ddc627fca32b1396d8b0b965dad62f63cc96da6e5a64c5a8c591aa",
        "0x1e97d007d9a26bfb87452dcb5fdccaaa43e6a9362ab2c6e4f619d45b53ba35b2",
        "0x08e075836b61edb61c9f7c710c4c77fdb24d2e10b070307cd689c99fbfd147e5",
        "0x2cab5d238910cd06fa3f15d86d2597f9ddae6abc926f60e550be101c6c46f216"]

      assert.equal(aggregatedPubKeys[0].toString(), web3.utils.toBN(expected[0]).toString())
      assert.equal(aggregatedPubKeys[1].toString(), web3.utils.toBN(expected[1]).toString())
      assert.equal(aggregatedPubKeys[2].toString(), web3.utils.toBN(expected[2]).toString())
      assert.equal(aggregatedPubKeys[3].toString(), web3.utils.toBN(expected[3]).toString())
    })

    it("should aggregate signatures", async () => {
      // signatures of the message 0x73616d706c65
      const signature1 = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
      const signature2 = "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"

      // aggregate both signatures
      const aggregatedSig = await blockRelay._aggregateSignature.call([signature1, signature2])

      const expected = await blockRelay._fromCompressed.call(
        "0x0210242b541d26e0eaf9996467281acb2b0294fd7cff3631b5faaeb5ac1d3741f7")

      const expected2 = ["0x10242B541D26E0EAF9996467281ACB2B0294FD7CFF3631B5FAAEB5AC1D3741F7",
        "0x22C6857A2F1068862313132914E4CAB33B352B8A79CBD65E71D5FBB5316EFFDC"]
      assert.equal(web3.utils.toBN(expected2[0]).toString(), web3.utils.toBN(expected[0]).toString())
      assert.equal(aggregatedSig[0].toString(), web3.utils.toBN(expected[0]).toString())
      assert.equal(aggregatedSig[1].toString(), web3.utils.toBN(expected[1]).toString())
    })

    it("should verify BLS signature1", async () => {
      // message signed
      const message = "0x73616d706c65"

      // signature of blockHash
      const signature1 = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"

      const compPublickey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
      const pubKeyCoordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
        "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
        "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
        "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

      // store both coordinates related with the public keys references
      await blockRelay.storeCoordinatesPublicKeys(compPublickey1, pubKeyCoordinates1)

      // verify the signature
      const pairing = await blockRelay.verifyBlsSignature.call(message, signature1,
        [pubKeyCoordinates1[0], pubKeyCoordinates1[1], pubKeyCoordinates1[2], pubKeyCoordinates1[3]])
      assert.equal(pairing, true)
    })

    it("should verify BLS signature2", async () => {
      // message signed
      const message = "0x73616d706c65"
      // signature of blockHash
      const signature2 = "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"

      const compPublickey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
      const pubKeyCoordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
        "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
        "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
        "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]

      await blockRelay.storeCoordinatesPublicKeys(compPublickey2, pubKeyCoordinates2)

      // verify the signature
      const pairing = await blockRelay.verifyBlsSignature.call(
        message, signature2,
        [pubKeyCoordinates2[0], pubKeyCoordinates2[1], pubKeyCoordinates2[2], pubKeyCoordinates2[3]])
      assert.equal(pairing, true)
    })

    it("should verify BLS signature aggregated", async () => {
      // message to be signed
      const message = "0x73616d706c65"

      // Signature1 from secret key 2009da7287c158b126123c113d1c85241b6e3294dd75c643588630a8bc0f934c
      const signature1 = "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
      // Signature2 from secret key 1ab1126ff2e37c6e6eddea943ccb3a48f83b380b856424ee552e113595525565
      const signature2 = "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"

      const aggregatedSignature = await blockRelay._aggregateSignature.call([signature1, signature2])

      const compPublicKey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
      const pubKeyCoordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
        "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
        "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
        "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

      const compPublicKey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
      const pubKeyCoordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
        "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
        "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
        "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]

      // store both public keys coordinates
      await blockRelay.storeCoordinatesPublicKeys(compPublicKey1, pubKeyCoordinates1)
      await blockRelay.storeCoordinatesPublicKeys(compPublicKey2, pubKeyCoordinates2)

      const aggregatedPubKey = await blockRelay.publickeysAggregation.call([compPublicKey1, compPublicKey2])

      // Verify the signature
      const pair = await blockRelay._verifyBlsSignature.call(
        message, [aggregatedSignature[0], aggregatedSignature[1]],
        [aggregatedPubKey[0], aggregatedPubKey[1], aggregatedPubKey[2], aggregatedPubKey[3]])
      assert.equal(pair, true)

      const pair2 = await blockRelay.verifyBlsSignature.call(
        message, "0x0210242b541d26e0eaf9996467281acb2b0294fd7cff3631b5faaeb5ac1d3741f7",
        [aggregatedPubKey[0], aggregatedPubKey[1], aggregatedPubKey[2], aggregatedPubKey[3]])
      assert.equal(pair2, true)
    })

    it("should propose a block2", async () => {
      // the arguments of the superblock to propose
      const blockIndex = "0x01"
      const drMerkleRoot = "0x0202020202020202020202020202020202020202020202020202020202020202"
      const tallyMerkleRoot = "0x0505050505050505050505050505050505050505050505050505050505050505"
      const lastBlockHash = "0x0303030303030303030303030303030303030303030303030303030303030303"
      const previousLastBlockHash = "0x0404040404040404040404040404040404040404040404040404040404040404"
      const arsLength = "0x1"
      const arsMerkleRoot = "0x0101010101010101010101010101010101010101010101010101010101010101"
      const blockHashes =
      [arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockHash, previousLastBlockHash, tallyMerkleRoot]

      const arsMerklePath = [1]

      // Signature1 of superblock "0x020f047a153e94b5f109e4013d1bd078112817cf0d58cdf6ba8891f9849852ba5b"
      // Signature2 of superblock "0x020a53003163aecfb532a16e701ff5f07c95d61ee2f9dbe209849f993a6d6a9900"
      const aggregatedSig = "0x0210242b541d26e0eaf9996467281acb2b0294fd7cff3631b5faaeb5ac1d3741f7"

      // public key from secret key 0x2009da7287c158b126123c113d1c85241b6e3294dd75c643588630a8bc0f934c
      const compPublicKey1 = "0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8"
      const pubKeyCoordinates1 = ["0x1cd5df38ed2f184b9830bfd3c2175d53c1455352307ead8cbd7c6201202f4aa8",
        "0x02ce1c4241143cc61d82589c9439c6dd60f81fa6f029625d58bc0f2e25e4ce89",
        "0x0ba19ae3b5a298b398b3b9d410c7e48c4c8c63a1d6b95b098289fbe1503d00fb",
        "0x2ec596e93402de0abc73ce741f37ed4984a0b59c96e20df8c9ea1c4e6ec04556"]

      // public key from secret key 0x1ab1126ff2e37c6e6eddea943ccb3a48f83b380b856424ee552e113595525565
      const compPublicKey2 = "0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78"
      const pubKeyCoordinates2 = ["0x28fe26becbdc0384aa67bf734d08ec78ecc2330f0aa02ad9da00f56c37907f78",
        "0x2cd080d897822a95a0fb103c54f06e9bf445f82f10fe37efce69ecb59514abc8",
        "0x237faeb0351a693a45d5d54aa9759f52a71d76edae2132616d6085a9b2228bf9",
        "0x0f46bd1ef47552c3089604c65a3e7154e3976410be01149b60d5a41a6053e6c2"]

      // store both public keys coordinates
      await blockRelay.storeCoordinatesPublicKeys(compPublicKey1, pubKeyCoordinates1)
      await blockRelay.storeCoordinatesPublicKeys(compPublicKey2, pubKeyCoordinates2)

      const pubKeys = [compPublicKey1, compPublicKey2]

      // propose Block
      await blockRelay.proposeBlock(
        blockHashes, arsMerklePath, aggregatedSig, pubKeys)

      // concatenation of the blockHash and the epoch to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(web3.utils.padLeft(lastBlockHash, 64)).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(blockIndex), 64
          )
        )
      )

      // get last beacon
      const beacon = await blockRelay.getLastBeacon.call()

      // should be equal the last beacon
      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })

    it("should calculate a vote by its arguments 1", async () => {
      // the blockHash to propose
      const blockIndex = "0x1"
      const drMerkleRoot = "0x0202020202020202020202020202020202020202020202020202020202020202"
      const tallyMerkleRoot = "0x0505050505050505050505050505050505050505050505050505050505050505"
      const lastBlockindex = "0x0303030303030303030303030303030303030303030303030303030303030303"
      const previousLastBlockindex = "0x0404040404040404040404040404040404040404040404040404040404040404"
      const arsLength = "0xfffffffffff"
      const arsMerkleRoot = "0x0101010101010101010101010101010101010101010101010101010101010101"

      const superblock = await blockRelay._calculateSuperblock.call(
        arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockindex, previousLastBlockindex, tallyMerkleRoot)

      assert.equal(superblock.toString(),
        54175192531512784900103026914073632190190243663644695424562906719980424999330)
    })

    it("should calculate a vote by its arguments 2", async () => {
      // the blockHash to propose
      const blockIndex = "0x0202020"
      const drMerkleRoot = "0x0202020202020202020202020202020202020202020202020202020202020202"
      const tallyMerkleRoot = "0x0505050505050505050505050505050505050505050505050505050505050505"
      const lastBlockindex = "0x0303030303030303030303030303030303030303030303030303030303030303"
      const previousLastBlockindex = "0x0404040404040404040404040404040404040404040404040404040404040404"
      const arsLength = "0xfffffffffff"
      const arsMerkleRoot = "0x0101010101010101010101010101010101010101010101010101010101010101"

      const superblock = await blockRelay._calculateSuperblock.call(
        arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockindex, previousLastBlockindex, tallyMerkleRoot)

      assert.equal(superblock.toString(),
        9802620241603431873351494587922142307904607016591623556946025581832976867995)
    })

    it("should calculate a vote by its arguments 3", async () => {
      // the blockHash to propose
      const blockIndex = "0x020a6b2"
      const drMerkleRoot = "0x0202020202020202020202020202020202020202020202020202020202020202"
      const tallyMerkleRoot = "0x0505050505050505050505050505050505050505050505050505050505050505"
      const lastBlockindex = "0x0303030303030303030303030303030303030303030303030303030303030303"
      const previousLastBlockindex = "0x0404040404040404040404040404040404040404040404040404040404040404"
      const arsLength = "0xa456b32c7"
      const arsMerkleRoot = "0x0101010101010101010101010101010101010101010101010101010101010101"

      const superblock = await blockRelay._calculateSuperblock.call(
        arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockindex, previousLastBlockindex, tallyMerkleRoot)

      assert.equal(superblock.toString(),
        64761267591290776020731196410732966973855482014803178025390444733014516066337)
    })

    it("should calculate a vote by its arguments 4", async () => {
      // the blockHash to propose
      const blockIndex = "0x020a6b2"
      const drMerkleRoot = "0x876564fd345ea"
      const tallyMerkleRoot = "0x543feab6575c"
      const lastBlockindex = "0x23986aecd34"
      const previousLastBlockindex = "0x98fe34ad3c5"
      const arsLength = "0xa456b32c7"
      const arsMerkleRoot = "0x34742d5a7c"

      const superblock = await blockRelay._calculateSuperblock.call(
        arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockindex, previousLastBlockindex, tallyMerkleRoot)

      assert.equal(superblock.toString(),
        4732806755286371469318211526976164369602149091990742932627733604693483985035)
    })

    it("should calculate a vote by its arguments 5", async () => {
      // the blockHash to propose
      const blockIndex = "0x76564fd"
      const drMerkleRoot = "0xffff"
      const tallyMerkleRoot = "0x020a6b256"
      const lastBlockindex = "0x23986aecd34"
      const previousLastBlockindex = "0x34ba23cc5"
      const arsLength = "0x1234ad3e5f"
      const arsMerkleRoot = "0x34742d5a7c"

      const superblock = await blockRelay._calculateSuperblock.call(
        arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockindex, previousLastBlockindex, tallyMerkleRoot)

      assert.equal(superblock.toString(),
        89004993156785064417750386691130737739737147100235710406308136579259750517283)
    })

    it("should calculate a vote by its arguments 6", async () => {
      // the blockHash to propose
      const blockIndex = "0xffffff"
      const drMerkleRoot = "0xfffffffffff"
      const tallyMerkleRoot = "0xfffffffffff"
      const lastBlockindex = "0xfffffffffff"
      const previousLastBlockindex = "0xfffffffffff"
      const arsLength = "0xfffffffffff"
      const arsMerkleRoot = "0xfffffffffff"

      const superblock = await blockRelay._calculateSuperblock.call(
        arsLength, arsMerkleRoot, drMerkleRoot, blockIndex, lastBlockindex, previousLastBlockindex, tallyMerkleRoot)

      assert.equal(superblock.toString(),
        33118165402765236364296057361388763511544640105636527556914997563372756882134)
    })
  })
})
