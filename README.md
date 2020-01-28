# witnet-ethereum-block-relay

`witnet-ethereum-block-relay` is an open source implementation of the Block Relay in Witnet.

 DISCLAIMER: this is a work in progress, meaning the contract could be voulnerable to attacks.

## About WBI and the Block Relay

The Bridge nodes interact through the Witnet Bridge Interface, a smart contract in charge of facilitating the communication between Witnet and samrt contract platmforms, such as Ethereum (click [here][wbi] for more information).
The block headers in Witnet need to be available to the WBI, meaning the WBI should get those headers that should be stored in some contract, the Block Relay, in Witnet. In order to assure the validity of the block headers, the Block Relay needs to guarantee a consensus protocol and a Finality Gadget. The documentation about the stages of the Block Relay can be found [here][block-relay].

## Connecting the Bridge and the Block Relay

Due to the above, the more isolated the Block Relay and the WBI are, the more secure. Considering this, a proxy contract has been implemented, which connects to the WBI and from which the Block Relay is called. This allows to upgrade the Block Relay when needed.
The following diagram shows the flow between the WBI and the Block Relay.

<p align=center>
<img src="./images/wbi_br.jpg" width="550">
</p>
<p align=center>
<em>Fig. 1: Connecting the WBI to the Block Relay.</em>
</p>

## BlockRelay based on ABS

The `ABSBlockRelay` is a work in progress contract that pretends to implement the Active Bridge Set (ABS) as the set in charge of proposing and posting blocks to the Block Relay. The ABS is updated in the WBI and is a subset of bridge nodes.

A block header is later finalized when 2/3 of the ABS agree on a vote. More precisely the flow is as follows:

1. During each epoch, the members of the ABS (Active Bridge Set) propose votes for the previous epoch. The vote contains the previous vote it extends.
2. When the epoch is changed and another vote is proposed, automatically, if 2/3 of the members achieved consensus on a vote, the ´postNewBlock´ function is called.
3. When a vote is posted in the Block Relay, the previous votes that extends are finalized as well. If the previous vote is already finalized, it simply asserts that the vote it extends is the correct one (i.e. the last block).

The finality implemented in this contract is foundamental for the final purpose of a decentralized block relay. However the use of the ABS as the voting committee must be changed since these are easily sybileable. Check the [Future steps](#future-steps) section to understand better the block relay design.

Limitations:

1. When a block is finalized by the ABS, it finalizes the previous pending ones (if needed). This means that the members of ABS for an epoch _n_ are the one finalizing votes for epochs in which they could not be members.
2. It is needed to implement a non-double-voting modifier that prevents an ABS member voting several times for the same vote.

## Contracts

This repository contains a proxy and two Block Relay contracts, the first centralized and the second ABS-based.

### BlockRelayProxy

The `BlockRelayProxy` is the proxy contract called by the WBI when deployed. It has the following methods:

- **upgradeBlockRelay**:
  - _description_: upgrades the address of the block relay.
  - _inputs_:
    - *_newAddress_*: Address of the block relay to be upgraded.

- **getLastBeacon**:
  - _description_: calls the last beacon from the block relay
  - _output_:
    - the last beacon as byte concatenation of (block_hash||epoch).

- **verifyDrPoi**:
  - _description_: Verifies the validity of a data request PoI against the DR merkle root
  - _inputs_:
    - *_poi_*: proof of inclusion as [sibling1, sibling2,..].
    - *_blockHash* the blockHash
    - *_index* the index in the merkle tree of the element to verify
    - *_element* the leaf to be verified

- **verifyTallyPoi**:
  - _description_: V Verifies the validity of a PoI against the tally merkle root
  - _inputs_:
    - *_poi_*: proof of inclusion as [sibling1, sibling2,..].
    - *_blockHash* the blockHash
    - *_index* the index in the merkle tree of the element to verify
    - *_element* the leaf to be verified

### BlockRelay

The `BlockRelay` contract has the following methods:

- **postNewBlock**:
  - _description_: post a new block into the block relay.
  - _inputs_:
    - *_blockHash*: Hash of the block header.
    - *_drMerkleRoot*: the root hash of the requests-only merkle tree as contained in the block header.
    - *_tallyMerkleRoot*: the root hash of the tallies-only merkle tree as contained in the block header.

- **readDrMerkleRoot**:
  - _description_: retrieve the requests-only merkle root hash that was reported for a specific block header.
  - _inputs_:
    - *_blockHash*: hash of the block header.
  - _output_:
    - requests-only merkle root hash in the block header.

- **readTallyMerkleRoot**:
  - _description_: retrieve the tallies-only merkle root hash that was reported for a specific block header.
  - _inputs_:
    - *_blockHash*: hash of the block header.
  - _output_:
    - tallies-only merkle root hash in the block header.

  **getLastBeacon**:
  - _description_: retrieve the last beacon that was inserted in the block relay.
  - _output_:
    - the last beacon as byte concatenation of (block_hash||epoch).

  **verifyDrPoi**:
  - _description_: Verifies the validity of a data request PoI against the DR merkle root
  - _inputs_:
    - *_poi_*: proof of inclusion as [sibling1, sibling2,..].
    - *_blockHash* the blockHash
    - *_index* the index in the merkle tree of the element to verify
    - *_element* the leaf to be verified

- **verifyTallyPoi**:
  - _description_: V Verifies the validity of a PoI against the tally merkle root
  - _inputs_:
    - *_poi_*: proof of inclusion as [sibling1, sibling2,..].
    - *_blockHash* the blockHash
    - *_index* the index in the merkle tree of the element to verify
    - *_element* the leaf to be verified

### ABSBlockRelay

The `ABSBlockRelay` contract is similar to the `BlockRelay` but adds some properties:

- Before posted, the blocks are proposed by members of the ABS.
- When a block is proposed by 2/3 of the members of the ABS, it is posted and that epoch is set as finalized.
- Each block when proposed is connected to a block in the previous epoch. This way, when a block is posted, in case the previous epochs were not finalized, the previous blocks are posted as well.

- **proposeBlock**:
  - _description_: proposes a new block candidate to be considered be added to the block relay.
  - _inputs_:
    - *_blockHash*: Hash of the block header.
    - *_epoch*: the epoch the block is prposed for, it has to be one epoch previous to the current epoch.
    - *_drMerkleRoot*: the root hash of the requests-only merkle tree as contained in the block header.
    - *_tallyMerkleRoot*: the root hash of the tallies-only merkle tree as contained in the block header.
    - *_previousBlock*: the previousVote that this proposed block vote extends.

- **postNewBlock**:
  - _description_: post a new block into the block relay.
  - _inputs_:
    - *_vote*: the vote to be posted, this is the hash of the concatenation of the inputs of ´propopseBlock´.
    - *_blockHash*: Hash of the block header.
    - *_epoch*: the epoch for which the block was proposed.
    - *_drMerkleRoot*: the root hash of the requests-only merkle tree as contained in the block header.
    - *_tallyMerkleRoot*: the root hash of the tallies-only merkle tree as contained in the block header.
    - *_previousVote*: the previousVote that this posted block vote extends.

## Known limitations:

- `CentralizedBlockRelay`: as the name suggests, this block relay is centralized, only the deployer of the contract is able to push blocks.
- `ABSBlockRelay`: the ABS stays the same until a block is finalized. A block can be proposed more than once by the same ABS member and olny for one epoch before the current epoch.

## Future steps

The next step is to integrate a block relay based on the Active Reputation Set (ARS), whose members had achieved enough reputation and so can be considered honest, please [follow the link][reputation-system] to get further information about the Reputation system in Witnet.

By doing so it needed to include the ARS merklelization as well as the proof of memberhip verification. Additionally should be implemented the Finality Gadget and BLS signatures. More details can be found [here][block-relay].

[reputation-system]: https://github.com/witnet/research/blob/master/reputation/docs/initialization.md
[block-relay]: https://github.com/witnet/research/blob/master/bridge/docs/block_relay.md
[wbi]: https://github.com/witnet/research/blob/master/bridge/docs/WBI.md

## License

`witnet-ethereum-block-relay` is published under the [MIT license][license].

[license]: https://github.com/witnet/witnet-ethereum-bridge/blob/master/LICENSE
