// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../core/interfaces/IAsset.sol";
import "../../core/interfaces/ICompliance.sol";
import "../../core/interfaces/IDocument.sol";
import "../../core/interfaces/IJurisdiction.sol";

/**
 * @title SupplyChainItem
 * @dev Implementation for tracking supply chain items across Southeast Asian jurisdictions
 */
contract SupplyChainItem {
    // Asset registry interface
    IAsset private _assetRegistry;
    
    // Compliance registry interface
    ICompliance private _complianceRegistry;
    
    // Document registry interface
    IDocument private _documentRegistry;
    
    // Jurisdiction registry interface
    IJurisdiction private _jurisdictionRegistry;
    
    // Contract owner
    address private _owner;
    
    // Mapping from item ID to item details
    mapping(bytes32 => Item) private _items;
    
    // Mapping from batch ID to item IDs
    mapping(bytes32 => bytes32[]) private _batchItems;
    
    // Enum representing the item status
    enum ItemStatus {
        CREATED,
        IN_TRANSIT,
        CUSTOMS_CLEARANCE,
        DELIVERED,
        REJECTED,
        RECALLED
    }
    
    // Struct containing item details
    struct Item {
        bytes32 id;
        string name;
        string description;
        string manufacturer;
        uint8 originJurisdiction;
        uint8 currentJurisdiction;
        bytes32 assetId;
        address owner;
        bytes32 batchId;
        ItemStatus status;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    // Struct containing location update details
    struct LocationUpdate {
        bytes32 itemId;
        uint8 previousJurisdiction;
        uint8 newJurisdiction;
        string location;
        string notes;
        uint256 timestamp;
    }
    
    // Mapping from item ID to location updates
    mapping(bytes32 => LocationUpdate[]) private _locationUpdates;
    
    // Events
    event ItemCreated(
        bytes32 indexed itemId,
        bytes32 indexed assetId,
        address indexed owner,
        string name,
        uint8 originJurisdiction,
        bytes32 batchId,
        uint256 timestamp
    );
    
    event ItemTransferred(
        bytes32 indexed itemId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );
    
    event ItemStatusUpdated(
        bytes32 indexed itemId,
        ItemStatus previousStatus,
        ItemStatus newStatus,
        uint256 timestamp
    );
    
    event ItemLocationUpdated(
        bytes32 indexed itemId,
        uint8 previousJurisdiction,
        uint8 newJurisdiction,
        string location,
        uint256 timestamp
    );
    
    /**
     * @dev Modifier to restrict function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "SupplyChainItem: caller is not the owner");
        _;
    }
    
    /**
     * @dev Modifier to restrict function access to the item owner
     * @param itemId The ID of the item
     */
    modifier onlyItemOwner(bytes32 itemId) {
        require(_items[itemId].owner == msg.sender, "SupplyChainItem: caller is not the item owner");
        _;
    }
    
    /**
     * @dev Constructor
     * @param assetRegistry Address of the asset registry contract
     * @param complianceRegistry Address of the compliance registry contract
     * @param documentRegistry Address of the document registry contract
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     */
    constructor(
        address assetRegistry,
        address complianceRegistry,
        address documentRegistry,
        address jurisdictionRegistry
    ) {
        _owner = msg.sender;
        _assetRegistry = IAsset(assetRegistry);
        _complianceRegistry = ICompliance(complianceRegistry);
        _documentRegistry = IDocument(documentRegistry);
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
    }
    
    /**
     * @dev Creates a new supply chain item
     * @param name The name of the item
     * @param description The description of the item
     * @param manufacturer The manufacturer of the item
     * @param originJurisdiction The jurisdiction code for the item's origin
     * @param batchId Optional batch ID for the item (0 for no batch)
     * @param documentIds Array of document IDs associated with the item
     * @return itemId The unique identifier for the created item
     */
    function createItem(
        string calldata name,
        string calldata description,
        string calldata manufacturer,
        uint8 originJurisdiction,
        bytes32 batchId,
        bytes32[] calldata documentIds
    ) external returns (bytes32 itemId) {
        // Check that the jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(originJurisdiction),
            "SupplyChainItem: jurisdiction is not active"
        );
        
        // Generate a unique item ID
        itemId = keccak256(abi.encodePacked(msg.sender, name, manufacturer, block.timestamp));
        
        // Create the item asset in the asset registry
        bytes32 assetId = _assetRegistry.createAsset(
            IAsset.AssetType.SUPPLY_CHAIN_ITEM,
            keccak256(abi.encodePacked(itemId)),
            originJurisdiction,
            abi.encode(name, description, manufacturer)
        );
        
        // Create the item
        Item memory item = Item({
            id: itemId,
            name: name,
            description: description,
            manufacturer: manufacturer,
            originJurisdiction: originJurisdiction,
            currentJurisdiction: originJurisdiction,
            assetId: assetId,
            owner: msg.sender,
            batchId: batchId,
            status: ItemStatus.CREATED,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        // Store the item
        _items[itemId] = item;
        
        // If a batch ID is provided, add the item to the batch
        if (batchId != bytes32(0)) {
            _batchItems[batchId].push(itemId);
        }
        
        // Link documents to the asset
        for (uint256 i = 0; i < documentIds.length; i++) {
            _documentRegistry.linkDocumentToAsset(documentIds[i], assetId, "ITEM_DOCUMENT");
        }
        
        // Check compliance
        ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(originJurisdiction);
        (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
            jurisdictionEnum,
            "SUPPLY_CHAIN_ITEM_CREATE",
            abi.encode(msg.sender, name, manufacturer)
        );
        
        require(isCompliant, "SupplyChainItem: item creation is not compliant");
        
        // Emit the item created event
        emit ItemCreated(
            itemId,
            assetId,
            msg.sender,
            name,
            originJurisdiction,
            batchId,
            block.timestamp
        );
        
        return itemId;
    }
    
    /**
     * @dev Transfers ownership of an item
     * @param itemId The ID of the item
     * @param newOwner The address of the new owner
     * @return success Whether the transfer was successful
     */
    function transferItem(bytes32 itemId, address newOwner)
        external
        onlyItemOwner(itemId)
        returns (bool success)
    {
        Item storage item = _items[itemId];
        
        // Transfer the asset in the asset registry
        bool assetTransferred = _assetRegistry.transferAsset(
            item.assetId,
            newOwner,
            abi.encode(itemId)
        );
        
        require(assetTransferred, "SupplyChainItem: asset transfer failed");
        
        // Store the previous owner for the event
        address previousOwner = item.owner;
        
        // Update the item owner
        item.owner = newOwner;
        item.updatedAt = block.timestamp;
        
        // Emit the item transferred event
        emit ItemTransferred(
            itemId,
            previousOwner,
            newOwner,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Updates the status of an item
     * @param itemId The ID of the item
     * @param newStatus The new status for the item
     * @return success Whether the update was successful
     */
    function updateItemStatus(bytes32 itemId, ItemStatus newStatus)
        external
        onlyItemOwner(itemId)
        returns (bool success)
    {
        Item storage item = _items[itemId];
        
        // Store the previous status for the event
        ItemStatus previousStatus = item.status;
        
        // Update the item status
        item.status = newStatus;
        item.updatedAt = block.timestamp;
        
        // Emit the item status updated event
        emit ItemStatusUpdated(
            itemId,
            previousStatus,
            newStatus,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Updates the location of an item
     * @param itemId The ID of the item
     * @param newJurisdiction The new jurisdiction code for the item
     * @param location The specific location within the jurisdiction
     * @param notes Additional notes about the location update
     * @return success Whether the update was successful
     */
    function updateItemLocation(
        bytes32 itemId,
        uint8 newJurisdiction,
        string calldata location,
        string calldata notes
    )
        external
        onlyItemOwner(itemId)
        returns (bool success)
    {
        // Check that the new jurisdiction is active
        require(
            _jurisdictionRegistry.isJurisdictionActive(newJurisdiction),
            "SupplyChainItem: new jurisdiction is not active"
        );
        
        Item storage item = _items[itemId];
        
        // Store the previous jurisdiction for the event
        uint8 previousJurisdiction = item.currentJurisdiction;
        
        // Update the item jurisdiction
        item.currentJurisdiction = newJurisdiction;
        item.updatedAt = block.timestamp;
        
        // Create a location update record
        LocationUpdate memory update = LocationUpdate({
            itemId: itemId,
            previousJurisdiction: previousJurisdiction,
            newJurisdiction: newJurisdiction,
            location: location,
            notes: notes,
            timestamp: block.timestamp
        });
        
        // Store the location update
        _locationUpdates[itemId].push(update);
        
        // Check compliance for cross-border movement
        if (previousJurisdiction != newJurisdiction) {
            ICompliance.Jurisdiction jurisdictionEnum = ICompliance.Jurisdiction(newJurisdiction);
            (bool isCompliant, ) = _complianceRegistry.isOperationCompliant(
                jurisdictionEnum,
                "SUPPLY_CHAIN_ITEM_IMPORT",
                abi.encode(msg.sender, itemId, previousJurisdiction)
            );
            
            require(isCompliant, "SupplyChainItem: item import is not compliant");
            
            // If the item is in transit, update to customs clearance
            if (item.status == ItemStatus.IN_TRANSIT) {
                item.status = ItemStatus.CUSTOMS_CLEARANCE;
                
                emit ItemStatusUpdated(
                    itemId,
                    ItemStatus.IN_TRANSIT,
                    ItemStatus.CUSTOMS_CLEARANCE,
                    block.timestamp
                );
            }
        }
        
        // Emit the item location updated event
        emit ItemLocationUpdated(
            itemId,
            previousJurisdiction,
            newJurisdiction,
            location,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @dev Gets the details of an item
     * @param itemId The ID of the item
     * @return item The item details
     */
    function getItem(bytes32 itemId) external view returns (Item memory item) {
        return _items[itemId];
    }
    
    /**
     * @dev Gets the location history of an item
     * @param itemId The ID of the item
     * @return updates Array of location updates for the item
     */
    function getItemLocationHistory(bytes32 itemId) external view returns (LocationUpdate[] memory updates) {
        return _locationUpdates[itemId];
    }
    
    /**
     * @dev Gets the items in a batch
     * @param batchId The ID of the batch
     * @return itemIds Array of item IDs in the batch
     */
    function getBatchItems(bytes32 batchId) external view returns (bytes32[] memory itemIds) {
        return _batchItems[batchId];
    }
    
    /**
     * @dev Gets the documents associated with an item
     * @param itemId The ID of the item
     * @return documentIds Array of document IDs associated with the item
     */
    function getItemDocuments(bytes32 itemId) external view returns (bytes32[] memory documentIds) {
        Item storage item = _items[itemId];
        return _documentRegistry.getDocumentsByAsset(item.assetId, "ITEM_DOCUMENT");
    }
    
    /**
     * @dev Sets the asset registry address
     * @param assetRegistry Address of the asset registry contract
     * @return success Whether the update was successful
     */
    function setAssetRegistry(address assetRegistry) external onlyOwner returns (bool success) {
        _assetRegistry = IAsset(assetRegistry);
        return true;
    }
    
    /**
     * @dev Sets the compliance registry address
     * @param complianceRegistry Address of the compliance registry contract
     * @return success Whether the update was successful
     */
    function setComplianceRegistry(address complianceRegistry) external onlyOwner returns (bool success) {
        _complianceRegistry = ICompliance(complianceRegistry);
        return true;
    }
    
    /**
     * @dev Sets the document registry address
     * @param documentRegistry Address of the document registry contract
     * @return success Whether the update was successful
     */
    function setDocumentRegistry(address documentRegistry) external onlyOwner returns (bool success) {
        _documentRegistry = IDocument(documentRegistry);
        return true;
    }
    
    /**
     * @dev Sets the jurisdiction registry address
     * @param jurisdictionRegistry Address of the jurisdiction registry contract
     * @return success Whether the update was successful
     */
    function setJurisdictionRegistry(address jurisdictionRegistry) external onlyOwner returns (bool success) {
        _jurisdictionRegistry = IJurisdiction(jurisdictionRegistry);
        return true;
    }
}
