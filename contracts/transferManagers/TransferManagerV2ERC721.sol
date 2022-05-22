// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {TransferManagerV2Core} from "./TransferManagerV2Core.sol";
import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";

/**
 * @title TransferManagerV2ERC721
 * @notice It allows the transfer of ERC721 tokens across multiple contract operators of the ecosystem.
 * @dev There is a whitelist set at this contract level and users must also approve each operator.
 */
contract TransferManagerV2ERC721 is ITransferManagerNFT, TransferManagerV2Core {
    /**
     * @notice Transfer ERC721 tokenId
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(_isTransferValid(from, msg.sender), "Transfer: Not valid");
        IERC721(collection).transferFrom(from, to, tokenId);
    }

    /**
     * @notice Batch transfer ERC721 tokens across multiple collections
     * @param collections array of collection addresses
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenIds array of tokenIds
     * @dev For ERC721, amounts is not used.
     */
    function batchTransferNonFungibleTokens(
        address[] calldata collections,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata
    ) external {
        require(collections.length == tokenIds.length, "Transfer: Wrong lengths");
        require(from == msg.sender || _isTransferValid(from, msg.sender), "Transfer: Not valid");
        for (uint256 i; i < collections.length; i++) {
            IERC721(collections[i]).transferFrom(from, to, tokenIds[i]);
        }
    }
}
