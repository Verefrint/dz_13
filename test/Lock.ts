import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { loadFixture, ethers, expect, network } from './setup.ts';

describe("Game test", async function() {

    async function deploy() {
        const [owner, user1, user2, user3, user4] = await ethers.getSigners()

        const signerAddresses = [
          [await user1.getAddress()],
          [await user2.getAddress()],
          [await user3.getAddress()],
          [await user4.getAddress()]
        ]

        const tree = StandardMerkleTree.of(signerAddresses, ["address"]);

        const factory = await ethers.getContractFactory("MerkleAirdrop", owner)
        const contract = await factory.deploy(tree.root)

        await contract.waitForDeployment()

        return {owner, user1, user2, user3, user4, tree, contract}
    }

    it('should mint token', async function() {
      const {owner, user1, user2, user3, user4, tree, contract} = await loadFixture(deploy)

      for (const [i, v] of tree.entries()) {
        if (v[0] === await user1.getAddress()) {
          const proof = tree.getProof(i);

          const mintPrice =100000000000000

          await expect(contract.connect(user1).mint(proof, {value: mintPrice})).to.emit(contract, "NFTMinted").withArgs(await user1.getAddress(), 1)
          expect (await contract.balanceOf(await user1.getAddress())).to.equal(1)

          //should not allow
          await expect(contract.connect(user1).mint(proof, {value: mintPrice})).to.be.revertedWithCustomError(contract, "TokenMintedOrNotAllowed")

          //should not allow too 
          const signerAddresses = [
            [await user2.getAddress()],
            [await user3.getAddress()],
            [await user1.getAddress()]
          ]
  
          const nTree = StandardMerkleTree.of(signerAddresses, ["address"]);

          await expect(contract.connect(owner).updateMerkleRoot(nTree.root)).emit(contract, "WhitelistUpdated").withArgs(nTree.root)

          //should not allow
          await expect(contract.connect(user4).mint(proof, {value: mintPrice})).to.be.revertedWithCustomError(contract, "InvalidProof")
        }
    }})
})