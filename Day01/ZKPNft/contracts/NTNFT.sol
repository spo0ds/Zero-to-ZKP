// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/INTNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Verifier.sol";

/*///////////////////////////////////////////////////////////////////////////////
                           CUSTOME ERROR 
//////////////////////////////////////////////////////////////////////////////*/

error NTNFT__NftNotTransferrable();
error NTNFT__CanOnlyMintOnce();
error NTNFT__NotNFTOwner();

/// @title OxAuth
/// @author Spooderman
/// @author daleon
/// @notice OxAuth provides the functionality to mint soul bound token but only one address could mint once.

contract NTNFT is INTNFT, ERC721 {
    /// @notice id of the NFT.

    using Counters for Counters.Counter;

    Verifier immutable verifier_sm;

    Counters.Counter private s_tokenCounter;

    /// @notice this mapping stores whether that particular address has already minted NFT or not.

    mapping(address => bool) private _minter;

    /*///////////////////////////////////////////////////////////////////////////////
                           Constructor
    //////////////////////////////////////////////////////////////////////////////*/

    /// @notice Gives name and symbol to the NFT.

    constructor(address _verifierAddress) ERC721("OxAuth", "Ox") {
        verifier_sm = Verifier(_verifierAddress);
    }

    /*///////////////////////////////////////////////////////////////////////////////
                           Modifier
    //////////////////////////////////////////////////////////////////////////////*/

    /// @notice passes if an address has not minted NFT before else reverts.

    modifier onlyOnceMint() {
        if (_minter[msg.sender]) {
            revert NTNFT__CanOnlyMintOnce();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////////////////////
                           mintNft
    //////////////////////////////////////////////////////////////////////////////*/

    /// @notice allows an address to mint an NFT.

    function mintNft(
        Verifier.Proof memory proof,
        uint[1] memory input
    ) external override onlyOnceMint returns (uint256) {
        // Verifier.Proof memory proof;
        // proof.a = Pairing.G1Point(
        //     0x299460cbbdab86d3ff62499c156c08ef87d7d2710a689cf470adcb2853b95b40,
        //     0x1e6dbc3505637285ff9554aac796a91675ff54028d21646d68987c1230557920
        // );
        // proof.b = Pairing.G2Point(
        //     [
        //         0x22747d2c3df6356a47c7090cc8c07e34f12a9b788ff5c0542fc95fba210fc69a,
        //         0x25b163e079df7567999b2907c7359e7bad444e6aa9690cc8f23a516225075f22
        //     ],
        //     [
        //         0x0feb24d851bab31f1418570e9c7d8de3fdc4776196df00b784f69f2a601c778c,
        //         0x1f604993c00ee7dc717bc4f1833759186959ab8a08e9af543931b2f74d564e40
        //     ]
        // );
        // proof.c = Pairing.G1Point(
        //     0x1f33fb3be02c25cd227abd8068d3678fe14229c70cb73d04c0a8784a7aadf021,
        //     0x197ee4de538949191f88efea3ec76ca3d1b62675fb237cb5b9eef0128b51087a
        // );

        require(verifier_sm.verifyTx(proof, input), "Invalid proof");
        uint256 tokenId = s_tokenCounter.current();
        s_tokenCounter.increment();
        _safeMint(msg.sender, tokenId);
        _minter[msg.sender] = true;
        return tokenId;
    }

    /*///////////////////////////////////////////////////////////////////////////////
                           sburn
    //////////////////////////////////////////////////////////////////////////////*/

    /// @notice allows an owner of the NFT to burn it.
    /// @param tokenId id of an NFT.

    function burn(uint tokenId) external override {
        if (ownerOf(tokenId) != msg.sender) {
            revert NTNFT__NotNFTOwner();
        }
        delete _minter[msg.sender];
        _burn(tokenId);
    }

    /*///////////////////////////////////////////////////////////////////////////////
                           View and Pure Functions
    //////////////////////////////////////////////////////////////////////////////*/

    /// @notice gets the token URI of an NFT.

    function tokenURI(
        uint /*tokenId*/
    ) public pure override returns (string memory) {
        return
            "https://ipfs.io/ipfs/Qmcx9T9WYxU2wLuk5bptJVwqjtxQPL8SxjgUkoEaDqWzti?filename=BasicNFT.png";
    }

    /// @notice gets the tokenCounter.
    function getTokenCounter() external view returns (uint) {
        return s_tokenCounter.current();
    }

    /// @notice returns whether an address has minted NFT or not
    function hasMinted(address minter) external view returns (bool) {
        return _minter[minter];
    }

    /*///////////////////////////////////////////////////////////////////////////////
                           Transfers and Approve Functions
    ///////////////////////////////////////////////////////////////////////////////*/

    /// --- Disabling Transfer Of Soulbound NFT --- ///

    /// @notice Function disabled as cannot transfer a soulbound nft
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function safeTransferFrom(address, address, uint256) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function transferFrom(address, address, uint256) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function approve(address, uint256) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function setApprovalForAll(address, bool) public pure override {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function getApproved(uint256) public pure override returns (address) {
        revert NTNFT__NftNotTransferrable();
    }

    /// @notice Function disabled as cannot transfer a soulbound nft
    function isApprovedForAll(
        address,
        address
    ) public pure override returns (bool) {
        revert NTNFT__NftNotTransferrable();
    }
}
