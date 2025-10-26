// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MerchantRegistry
 * @dev Registry for merchants to register and manage their profiles
 */
contract MerchantRegistry is Ownable {
    struct Merchant {
        address walletAddress;
        string businessName;
        string category;
        string location;
        uint256 registrationDate;
        bool isActive;
        uint256 totalTransactions;
        uint256 totalVolume;
    }

    mapping(address => Merchant) public merchants;
    address[] public merchantAddresses;
    mapping(address => bool) public authorizedCallers;

    event MerchantRegistered(
        address indexed merchantAddress,
        string businessName,
        string category,
        uint256 registrationDate
    );

    event MerchantUpdated(
        address indexed merchantAddress,
        string businessName
    );

    event MerchantDeactivated(address indexed merchantAddress);

    event TransactionRecorded(
        address indexed merchant,
        uint256 amount,
        uint256 timestamp
    );

    event AuthorizedCallerUpdated(
        address indexed caller,
        bool authorized
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Set authorized caller (e.g., PaymentProcessor)
     */
    function setAuthorizedCaller(address _caller, bool _authorized) external onlyOwner {
        authorizedCallers[_caller] = _authorized;
        emit AuthorizedCallerUpdated(_caller, _authorized);
    }

    /**
     * @dev Register a new merchant
     */
    function registerMerchant(
        string memory _businessName,
        string memory _category,
        string memory _location
    ) external {
        require(!merchants[msg.sender].isActive, "Merchant already registered");
        require(bytes(_businessName).length > 0, "Business name required");

        merchants[msg.sender] = Merchant({
            walletAddress: msg.sender,
            businessName: _businessName,
            category: _category,
            location: _location,
            registrationDate: block.timestamp,
            isActive: true,
            totalTransactions: 0,
            totalVolume: 0
        });

        merchantAddresses.push(msg.sender);

        emit MerchantRegistered(
            msg.sender,
            _businessName,
            _category,
            block.timestamp
        );
    }

    /**
     * @dev Update merchant profile
     */
    function updateMerchant(
        string memory _businessName,
        string memory _category,
        string memory _location
    ) external {
        require(merchants[msg.sender].isActive, "Merchant not registered");

        merchants[msg.sender].businessName = _businessName;
        merchants[msg.sender].category = _category;
        merchants[msg.sender].location = _location;

        emit MerchantUpdated(msg.sender, _businessName);
    }

    /**
     * @dev Record a transaction for a merchant (called by PaymentProcessor)
     */
    function recordTransaction(address _merchant, uint256 _amount) external {
        require(authorizedCallers[msg.sender], "Not authorized to record transactions");
        require(merchants[_merchant].isActive, "Merchant not active");
        
        merchants[_merchant].totalTransactions += 1;
        merchants[_merchant].totalVolume += _amount;

        emit TransactionRecorded(_merchant, _amount, block.timestamp);
    }

    /**
     * @dev Get merchant details
     */
    function getMerchant(address _merchantAddress)
        external
        view
        returns (
            string memory businessName,
            string memory category,
            string memory location,
            uint256 registrationDate,
            bool isActive,
            uint256 totalTransactions,
            uint256 totalVolume
        )
    {
        Merchant memory merchant = merchants[_merchantAddress];
        return (
            merchant.businessName,
            merchant.category,
            merchant.location,
            merchant.registrationDate,
            merchant.isActive,
            merchant.totalTransactions,
            merchant.totalVolume
        );
    }

    /**
     * @dev Check if an address is a registered merchant
     */
    function isMerchant(address _address) external view returns (bool) {
        return merchants[_address].isActive;
    }

    /**
     * @dev Get total number of merchants
     */
    function getMerchantCount() external view returns (uint256) {
        return merchantAddresses.length;
    }

    /**
     * @dev Deactivate merchant (only owner)
     */
    function deactivateMerchant(address _merchantAddress) external onlyOwner {
        require(merchants[_merchantAddress].isActive, "Merchant not active");
        merchants[_merchantAddress].isActive = false;
        emit MerchantDeactivated(_merchantAddress);
    }
}
