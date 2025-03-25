// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IJurisdiction.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title JurisdictionRegistry
 * @dev Implementation of the IJurisdiction interface for managing jurisdiction-specific rules
 */
contract JurisdictionRegistry is IJurisdiction {
    // Mapping from jurisdiction ID to jurisdiction details
    mapping(uint8 => JurisdictionInfo) private _jurisdictions;
    
    // Array of all jurisdiction IDs
    uint8[] private _jurisdictionIds;
    
    // Array of active jurisdiction IDs
    uint8[] private _activeJurisdictionIds;
    
    // Mapping from jurisdiction ID to operation type to allowed status
    mapping(uint8 => mapping(string => bool)) private _allowedOperations;
    
    // Mapping from jurisdiction ID to operation type to reason
    mapping(uint8 => mapping(string => string)) private _operationRestrictionReasons;
    
    // Contract owner
    address private _owner;
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "JurisdictionRegistry: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the jurisdiction regulator
     * @param jurisdictionId The ID of the jurisdiction
     */
    modifier onlyRegulator(uint8 jurisdictionId) {
        require(_jurisdictions[jurisdictionId].regulator == msg.sender, "JurisdictionRegistry: caller is not the regulator");
        _;
    }
    
    /**
     * @dev Constructor
     */
    constructor() {
        _owner = msg.sender;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function registerJurisdiction(
        uint8 id,
        string calldata name,
        string calldata countryCode,
        address regulator,
        bytes32 rulesHash
    ) external override onlyOwner returns (bool success) {
        // Check that the jurisdiction doesn't already exist
        require(_jurisdictions[id].regulator == address(0), "JurisdictionRegistry: jurisdiction already exists");
        
        // Create the jurisdiction
        JurisdictionInfo memory info = JurisdictionInfo({
            id: id,
            name: name,
            countryCode: countryCode,
            active: true,
            regulator: regulator,
            rulesHash: rulesHash,
            updatedAt: block.timestamp
        });
        
        // Store the jurisdiction
        _jurisdictions[id] = info;
        _jurisdictionIds.push(id);
        _activeJurisdictionIds.push(id);
        
        // Emit the jurisdiction registration event
        emit JurisdictionRegistered(
            id,
            name,
            countryCode,
            regulator,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function updateJurisdictionRules(
        uint8 jurisdictionId,
        bytes32 newRulesHash,
        bytes calldata data
    ) external override onlyRegulator(jurisdictionId) returns (bool success) {
        JurisdictionInfo storage info = _jurisdictions[jurisdictionId];
        
        // Store the previous rules hash for the event
        bytes32 previousRulesHash = info.rulesHash;
        
        // Update the rules hash
        info.rulesHash = newRulesHash;
        info.updatedAt = block.timestamp;
        
        // Emit the rules update event
        emit JurisdictionRulesUpdated(
            jurisdictionId,
            previousRulesHash,
            newRulesHash,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function setJurisdictionStatus(uint8 jurisdictionId, bool active)
        external
        override
        onlyOwner
        returns (bool success)
    {
        JurisdictionInfo storage info = _jurisdictions[jurisdictionId];
        
        // Check that the jurisdiction exists
        require(info.regulator != address(0), "JurisdictionRegistry: jurisdiction does not exist");
        
        // Update the active status only if it's different
        if (info.active != active) {
            info.active = active;
            info.updatedAt = block.timestamp;
            
            // Update the active jurisdictions array
            if (active) {
                // Add to active jurisdictions
                bool found = false;
                for (uint256 i = 0; i < _activeJurisdictionIds.length; i++) {
                    if (_activeJurisdictionIds[i] == jurisdictionId) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    _activeJurisdictionIds.push(jurisdictionId);
                }
            } else {
                // Remove from active jurisdictions
                for (uint256 i = 0; i < _activeJurisdictionIds.length; i++) {
                    if (_activeJurisdictionIds[i] == jurisdictionId) {
                        // Replace with the last element and pop
                        _activeJurisdictionIds[i] = _activeJurisdictionIds[_activeJurisdictionIds.length - 1];
                        _activeJurisdictionIds.pop();
                        break;
                    }
                }
            }
            
            // Emit the status change event
            emit JurisdictionStatusChanged(
                jurisdictionId,
                active,
                block.timestamp
            );
        }
        
        return true;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function getJurisdictionInfo(uint8 jurisdictionId)
        external
        view
        override
        returns (JurisdictionInfo memory info)
    {
        return _jurisdictions[jurisdictionId];
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function isJurisdictionActive(uint8 jurisdictionId)
        external
        view
        override
        returns (bool isActive)
    {
        return _jurisdictions[jurisdictionId].active;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function getJurisdictionRegulator(uint8 jurisdictionId)
        external
        view
        override
        returns (address regulator)
    {
        return _jurisdictions[jurisdictionId].regulator;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function getActiveJurisdictions()
        external
        view
        override
        returns (uint8[] memory jurisdictionIds)
    {
        return _activeJurisdictionIds;
    }
    
    /**
     * @inheritdoc IJurisdiction
     */
    function isOperationAllowed(
        uint8 jurisdictionId,
        string calldata operationType,
        bytes calldata data
    ) external view override returns (bool isAllowed, string memory reason) {
        // Check that the jurisdiction exists and is active
        JurisdictionInfo storage info = _jurisdictions[jurisdictionId];
        if (info.regulator == address(0)) {
            return (false, "Jurisdiction does not exist");
        }
        if (!info.active) {
            return (false, "Jurisdiction is not active");
        }
        
        // Check if the operation is explicitly allowed or restricted
        if (_allowedOperations[jurisdictionId][operationType]) {
            return (true, "");
        } else if (bytes(_operationRestrictionReasons[jurisdictionId][operationType]).length > 0) {
            return (false, _operationRestrictionReasons[jurisdictionId][operationType]);
        }
        
        // Default to allowed if not explicitly restricted
        return (true, "");
    }
    
    /**
     * @dev Sets whether an operation is allowed in a jurisdiction
     * @param jurisdictionId The ID of the jurisdiction
     * @param operationType The type of operation
     * @param allowed Whether the operation is allowed
     * @param reason Reason if not allowed
     * @return success Whether the update was successful
     */
    function setOperationAllowed(
        uint8 jurisdictionId,
        string calldata operationType,
        bool allowed,
        string calldata reason
    ) external onlyRegulator(jurisdictionId) returns (bool success) {
        _allowedOperations[jurisdictionId][operationType] = allowed;
        
        if (!allowed) {
            _operationRestrictionReasons[jurisdictionId][operationType] = reason;
        } else {
            delete _operationRestrictionReasons[jurisdictionId][operationType];
        }
        
        return true;
    }
    
    /**
     * @dev Gets all jurisdictions
     * @return jurisdictionIds Array of all jurisdiction IDs
     */
    function getAllJurisdictions() external view returns (uint8[] memory jurisdictionIds) {
        return _jurisdictionIds;
    }
    
    /**
     * @dev Updates the regulator for a jurisdiction
     * @param jurisdictionId The ID of the jurisdiction
     * @param newRegulator The address of the new regulator
     * @return success Whether the update was successful
     */
    function updateRegulator(uint8 jurisdictionId, address newRegulator) external onlyOwner returns (bool success) {
        JurisdictionInfo storage info = _jurisdictions[jurisdictionId];
        
        // Check that the jurisdiction exists
        require(info.regulator != address(0), "JurisdictionRegistry: jurisdiction does not exist");
        
        // Update the regulator
        info.regulator = newRegulator;
        info.updatedAt = block.timestamp;
        
        return true;
    }
}
