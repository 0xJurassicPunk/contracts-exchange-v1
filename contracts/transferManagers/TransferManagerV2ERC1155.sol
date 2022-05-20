// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {TransferManagerV2Core} from "./TransferManagerV2Core.sol";
import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";

/**
 * @title TransferManagerV2ERC1155
 * @notice It allows the transfer of ERC1155 tokens across multiple contract operators of the ecosystem.
 * @dev There is a whitelist set at this contract level and users must also approve each operator.
 */
contract TransferManagerV2ERC1155 is ITransferManagerNFT, TransferManagerV2Core {
    /**
     * @notice Transfer ERC721 tokenId
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of token to transfer
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(_isTransferValid(from, msg.sender), "Transfer: Not valid");

        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
    }

    /**
     * @notice Batch transfer ERC1155 tokens across multiple collections
     * @param collections array of collection addresses
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenIds array of array of tokenIds
     * @param amounts array of array of amounts
     */
    function batchTransferNonFungibleTokens(
        address[] calldata collections,
        address from,
        address to,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external {
        require(collections.length == tokenIds.length, "Transfer: Wrong lengths");
        require(from == msg.sender || _isTransferValid(from, msg.sender), "Transfer: Not valid");

        for (uint256 i; i < collections.length; i++) {
            IERC1155(collections[i]).safeBatchTransferFrom(from, to, tokenIds[i], amounts[i], "");
        }
    }
}
