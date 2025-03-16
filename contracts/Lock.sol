// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error SmallSumForMint();
error TokenMintedOrNotAllowed();
error InvalidProof();

contract MerkleAirdrop is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {

    event WhitelistUpdated(bytes32 merkleRoot);
    event NFTMinted(address indexed user, uint256 tokenId);

    uint tokenId;
    uint private priceForMint  = 100_000_000_000_000;
    string constant tokenUri = "https://ipfs.io/ipfs/bafkreievgibi55znfubyt7u4zeh45bq3vkh3jy3bsnkpj7edamos4jrepi";
    mapping(address => bool) isMinted;

    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) ERC721("Merkle", "MRK") Ownable(msg.sender) {
        merkleRoot = _merkleRoot; 
    }

     function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function changePriceForMint(uint _price) external onlyOwner {
        priceForMint = _price;
    }

    function realMint() private {
        require(msg.value >= priceForMint, SmallSumForMint());

        ERC721._safeMint(msg.sender, tokenId);
        ERC721URIStorage._setTokenURI(tokenId, tokenUri);

        tokenId++;
    }

    //merkle tree
    function updateMerkleRoot(bytes32 root) public onlyOwner{
        merkleRoot = root;

        emit WhitelistUpdated(root);
    }

    function mint(bytes32[] calldata proof) external payable {
        require(isMinted[msg.sender] == false, TokenMintedOrNotAllowed());

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        require(MerkleProof.verify(proof, merkleRoot, leaf), InvalidProof());

        realMint();

        isMinted[msg.sender] = true;

        emit NFTMinted(msg.sender, tokenId);
    }
}
