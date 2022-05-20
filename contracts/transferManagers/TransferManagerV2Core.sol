// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title TransferManagerV2Core
 * @notice Core functions of TransferManagerV2 contracts
 */
abstract contract TransferManagerV2Core is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Whether user has approved operator
    mapping(address => mapping(address => bool)) internal _hasUserApprovedOperator;

    // Whitelist of operators
    EnumerableSet.AddressSet internal _whitelistedOperators;

    event ApprovalsGranted(address indexed user, address[] operators);
    event ApprovalsRemoved(address indexed user, address[] operators);
    event OperatorRemoved(address indexed operator);
    event OperatorWhitelisted(address indexed operator);

    /**
     * @notice Grant approvals for list of operators on behalf of the sender
     * @param operators array of operator addresses
     * @dev Each operator address must be globally whitelisted to be approved.
     */
    function grantApprovals(address[] calldata operators) external {
        require(operators.length > 0, "Approval: Length must be > 0");

        for (uint256 i; i < operators.length; i++) {
            require(_whitelistedOperators.contains(operators[i]), "Approval: Not whitelisted");
            require(!_hasUserApprovedOperator[msg.sender][operators[i]], "Approval: Already approved");
            _hasUserApprovedOperator[msg.sender][operators[i]] = true;
        }

        emit ApprovalsGranted(msg.sender, operators);
    }

    /**
     * @notice Revoke all approvals for the sender
     * @param operators array of operator addresses
     * @dev Each operator address must be approved at the user level to be revoked.
     */
    function revokeApprovals(address[] calldata operators) external {
        require(operators.length > 0, "Approval: Length must be > 0");

        for (uint256 i; i < operators.length; i++) {
            require(_hasUserApprovedOperator[msg.sender][operators[i]], "Revoke: Not approved");
            _hasUserApprovedOperator[msg.sender][operators[i]] = false;
        }

        emit ApprovalsRemoved(msg.sender, operators);
    }

    /**
     * @notice Whitelist an operator in the system
     * @param operator address of the operator to add
     */
    function whitelistOperator(address operator) external onlyOwner {
        require(!_whitelistedOperators.contains(operator), "Operator: Already whitelisted");
        _whitelistedOperators.add(operator);

        emit OperatorWhitelisted(operator);
    }

    /**
     * @notice Remove an operator from the system
     * @param operator address of the operator to remove
     */
    function removeOperator(address operator) external onlyOwner {
        require(_whitelistedOperators.contains(operator), "Operator: Not whitelisted");
        _whitelistedOperators.remove(operator);

        emit OperatorRemoved(operator);
    }

    /**
     * @notice Check whether transfer is valid
     * @param user address of the user
     * @param operator address of the operator
     */
    function _isTransferValid(address user, address operator) internal view returns (bool) {
        return _whitelistedOperators.contains(operator) && _hasUserApprovedOperator[user][operator];
    }

    /**
     * @notice Check whether user has approved a list of operator addresses
     * @param user address of the user
     * @param operators array of operator addresses
     */
    function hasUserApprovedOperators(address user, address[] calldata operators)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory operatorApprovals = new bool[](operators.length);

        for (uint256 i; i < operators.length; i++) {
            operatorApprovals[i] = _hasUserApprovedOperator[user][operators[i]];
        }

        return operatorApprovals;
    }

    /**
     * @notice See whitelisted operators in the system
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewWhitelistedOperators(uint256 cursor, uint256 size) external view returns (address[] memory, uint256) {
        uint256 length = size;

        if (length > _whitelistedOperators.length() - cursor) {
            length = _whitelistedOperators.length() - cursor;
        }

        address[] memory whitelistedOperators = new address[](length);

        for (uint256 i; i < length; i++) {
            whitelistedOperators[i] = _whitelistedOperators.at(cursor + i);
        }

        return (whitelistedOperators, cursor + length);
    }
}
