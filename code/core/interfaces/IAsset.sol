// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IAsset
 * @dev Interface for asset management across different jurisdictions
 * @notice This interface defines the standard methods for asset creation, transfer, and management
 */
interface IAsset {
    /**
     * @dev Enum representing the asset types
     */
    enum AssetType {
        REAL_ESTATE,
        SUPPLY_CHAIN_ITEM,
        LEGAL_CONTRACT,
        INSURANCE_POLICY,
        PAYMENT_INSTRUMENT
    }

    /**
     * @dev Enum representing the asset status
     */
    enum AssetStatus {
        CREATED,
        ACTIVE,
        LOCKED,
        TRANSFERRED,
        EXPIRED,
        TERMINATED
    }

    /**
     * @dev Struct containing asset details
     */
    struct Asset {
        bytes32 id;
        AssetType assetType;
        address owner;
        bytes32 metadataHash;
        AssetStatus status;
        uint8 jurisdiction;
        uint256 createdAt;
        uint256 updatedAt;
    }

    /**
     * @dev Event emitted when an asset is created
     */
    event AssetCreated(
        bytes32 indexed assetId,
        AssetType indexed assetType,
        address indexed owner,
        bytes32 metadataHash,
        uint8 jurisdiction,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when an asset is transferred
     */
    event AssetTransferred(
        bytes32 indexed assetId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when an asset status is updated
     */
    event AssetStatusUpdated(
        bytes32 indexed assetId,
        AssetStatus previousStatus,
        AssetStatus newStatus,
        uint256 timestamp
    );

    /**
     * @dev Creates a new asset
     * @param assetType The type of asset to create
     * @param metadataHash IPFS hash of the asset metadata
     * @param jurisdiction The jurisdiction code for the asset
     * @param data Additional data required for asset creation
     * @return assetId The unique identifier for the created asset
     */
    function createAsset(
        AssetType assetType,
        bytes32 metadataHash,
        uint8 jurisdiction,
        bytes calldata data
    ) external returns (bytes32 assetId);

    /**
     * @dev Transfers an asset to a new owner
     * @param assetId The unique identifier of the asset
     * @param newOwner The address of the new owner
     * @param data Additional data required for the transfer
     * @return success Whether the transfer was successful
     */
    function transferAsset(
        bytes32 assetId,
        address newOwner,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Gets the details of an asset
     * @param assetId The unique identifier of the asset
     * @return asset The asset details
     */
    function getAsset(bytes32 assetId) external view returns (Asset memory asset);

    /**
     * @dev Gets the owner of an asset
     * @param assetId The unique identifier of the asset
     * @return owner The address of the asset owner
     */
    function ownerOf(bytes32 assetId) external view returns (address owner);

    /**
     * @dev Updates the status of an asset
     * @param assetId The unique identifier of the asset
     * @param newStatus The new status for the asset
     * @param data Additional data required for the status update
     * @return success Whether the status update was successful
     */
    function updateAssetStatus(
        bytes32 assetId,
        AssetStatus newStatus,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Updates the metadata of an asset
     * @param assetId The unique identifier of the asset
     * @param newMetadataHash The new IPFS hash of the asset metadata
     * @param data Additional data required for the metadata update
     * @return success Whether the metadata update was successful
     */
    function updateAssetMetadata(
        bytes32 assetId,
        bytes32 newMetadataHash,
        bytes calldata data
    ) external returns (bool success);

    /**
     * @dev Gets the assets owned by an address
     * @param owner The address to check
     * @param assetType Optional filter by asset type (0 for all types)
     * @param startIndex Start index for pagination
     * @param limit Maximum number of assets to return
     * @return assetIds Array of asset IDs owned by the address
     * @return totalCount Total number of assets owned by the address
     */
    function getAssetsByOwner(
        address owner,
        uint8 assetType,
        uint256 startIndex,
        uint256 limit
    ) external view returns (bytes32[] memory assetIds, uint256 totalCount);
}
