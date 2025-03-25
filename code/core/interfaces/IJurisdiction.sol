// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IJurisdiction
 * @dev Interface for jurisdiction-specific rules and configurations
 * @notice This interface defines the standard methods for managing jurisdiction-specific rules
 */
interface IJurisdiction {
    /**
     * @dev Struct containing jurisdiction details
     */
    struct JurisdictionInfo {
        uint8 id;
        string name;
        string countryCode;
        bool active;
        address regulator;
        bytes32 rulesHash;
        uint256 updatedAt;
    }

    /**
     * @dev Event emitted when a jurisdiction is registered
     */
    event JurisdictionRegistered(
        uint8 indexed jurisdictionId,
        string name,
        string countryCode,
        address regulator,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when jurisdiction rules are updated
     */
    event JurisdictionRulesUpdated(
        uint8 indexed jurisdictionId,
        bytes32 previousRulesHash,
        bytes32 newRulesHash,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a jurisdiction status is changed
     */
    event JurisdictionStatusChanged(
        uint8 indexed jurisdictionId,
        bool active,
        uint256 timestamp
    );

    /**
     * @dev Registers a new jurisdiction
     * @param id The unique identifier for the jurisdiction
     * @param name The name of the jurisdiction
     * @param countryCode The ISO country code
     * @param regulator The address of the regulatory authority
     * @param rulesHash IPFS hash of the jurisdiction rules
     * @return success Whether the registration was successful
     */
    function registerJurisdiction(
        uint8 id,
        string calldata name,
        string calldata countryCode,
        address regulator,
        bytes32 rulesHash
    ) external returns (bool success);

    /**
     * @dev Updates the rules for a jurisdiction
     * @param jurisdictionId The unique identifier of the jurisdiction
     * @param newRulesHash IPFS hash of the new jurisdiction rules
     * @param data Additional data for the rules update
     * @return success Whether the update was successful
     */
    function updateJurisdictionRules(
        uint8 jurisdictionId,
        bytes32 newRulesHash,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Sets the active status of a jurisdiction
     * @param jurisdictionId The unique identifier of the jurisdiction
     * @param active Whether the jurisdiction is active
     * @return success Whether the status change was successful
     */
    function setJurisdictionStatus(uint8 jurisdictionId, bool active)
        external
        returns (bool success);

    /**
     * @dev Gets the details of a jurisdiction
     * @param jurisdictionId The unique identifier of the jurisdiction
     * @return info The jurisdiction details
     */
    function getJurisdictionInfo(uint8 jurisdictionId)
        external
        view
        returns (JurisdictionInfo memory info);

    /**
     * @dev Checks if a jurisdiction is active
     * @param jurisdictionId The unique identifier of the jurisdiction
     * @return isActive Whether the jurisdiction is active
     */
    function isJurisdictionActive(uint8 jurisdictionId)
        external
        view
        returns (bool isActive);

    /**
     * @dev Gets the regulator address for a jurisdiction
     * @param jurisdictionId The unique identifier of the jurisdiction
     * @return regulator The address of the regulatory authority
     */
    function getJurisdictionRegulator(uint8 jurisdictionId)
        external
        view
        returns (address regulator);

    /**
     * @dev Gets all active jurisdictions
     * @return jurisdictionIds Array of active jurisdiction IDs
     */
    function getActiveJurisdictions()
        external
        view
        returns (uint8[] memory jurisdictionIds);

    /**
     * @dev Checks if an operation is allowed in a jurisdiction
     * @param jurisdictionId The unique identifier of the jurisdiction
     * @param operationType The type of operation to check
     * @param data Additional data for the check
     * @return isAllowed Whether the operation is allowed
     * @return reason Reason if not allowed
     */
    function isOperationAllowed(
        uint8 jurisdictionId,
        string calldata operationType,
        bytes calldata data
    ) external view returns (bool isAllowed, string memory reason);
}
