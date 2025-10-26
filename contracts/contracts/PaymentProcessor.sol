// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IMerchantRegistry
 * @dev Interface for MerchantRegistry contract
 */
interface IMerchantRegistry {
    function recordTransaction(address _merchant, uint256 _amount) external;
    function isMerchant(address _address) external view returns (bool);
}

/**
 * @title PaymentProcessor
 * @dev Process payments between customers and merchants in CELO or cUSD
 */
contract PaymentProcessor is Ownable, ReentrancyGuard {
    IERC20 public cUSDToken;
    IMerchantRegistry public merchantRegistry;

    struct Payment {
        address customer;
        address merchant;
        uint256 amount;
        address token; // CELO (address(0)) or cUSD token address
        uint256 timestamp;
        string note;
    }

    mapping(bytes32 => Payment) public payments;
    bytes32[] public paymentIds;
    
    mapping(address => bytes32[]) public customerPayments;
    mapping(address => bytes32[]) public merchantPayments;

    event PaymentProcessed(
        bytes32 indexed paymentId,
        address indexed customer,
        address indexed merchant,
        uint256 amount,
        address token,
        uint256 timestamp
    );

    constructor(address _cUSDToken, address _merchantRegistry) Ownable(msg.sender) {
        cUSDToken = IERC20(_cUSDToken);
        merchantRegistry = IMerchantRegistry(_merchantRegistry);
    }

    /**
     * @dev Set merchant registry contract address
     */
    function setMerchantRegistry(address _merchantRegistry) external onlyOwner {
        merchantRegistry = IMerchantRegistry(_merchantRegistry);
    }

    /**
     * @dev Process payment in CELO (native token)
     */
    function payWithCELO(address _merchant, string memory _note)
        external
        payable
        nonReentrant
    {
        require(msg.value > 0, "Payment amount must be greater than 0");
        require(_merchant != address(0), "Invalid merchant address");
        require(_merchant != msg.sender, "Cannot pay yourself");

        // Transfer CELO to merchant
        (bool success, ) = _merchant.call{value: msg.value}("");
        require(success, "CELO transfer failed");

        // Update merchant transaction stats in MerchantRegistry
        if (address(merchantRegistry) != address(0)) {
            merchantRegistry.recordTransaction(_merchant, msg.value);
        }

        // Record payment
        bytes32 paymentId = _recordPayment(
            msg.sender,
            _merchant,
            msg.value,
            address(0), // address(0) represents CELO
            _note
        );

        emit PaymentProcessed(
            paymentId,
            msg.sender,
            _merchant,
            msg.value,
            address(0),
            block.timestamp
        );
    }

    /**
     * @dev Process payment in cUSD (stable token)
     */
    function payWithCUSD(
        address _merchant,
        uint256 _amount,
        string memory _note
    ) external nonReentrant {
        require(_amount > 0, "Payment amount must be greater than 0");
        require(_merchant != address(0), "Invalid merchant address");
        require(_merchant != msg.sender, "Cannot pay yourself");

        // Transfer cUSD from customer to merchant
        bool success = cUSDToken.transferFrom(msg.sender, _merchant, _amount);
        require(success, "cUSD transfer failed");

        // Update merchant transaction stats in MerchantRegistry
        if (address(merchantRegistry) != address(0)) {
            merchantRegistry.recordTransaction(_merchant, _amount);
        }

        // Record payment
        bytes32 paymentId = _recordPayment(
            msg.sender,
            _merchant,
            _amount,
            address(cUSDToken),
            _note
        );

        emit PaymentProcessed(
            paymentId,
            msg.sender,
            _merchant,
            _amount,
            address(cUSDToken),
            block.timestamp
        );
    }

    /**
     * @dev Internal function to record payment
     */
    function _recordPayment(
        address _customer,
        address _merchant,
        uint256 _amount,
        address _token,
        string memory _note
    ) internal returns (bytes32) {
        bytes32 paymentId = keccak256(
            abi.encodePacked(
                _customer,
                _merchant,
                _amount,
                _token,
                block.timestamp,
                paymentIds.length
            )
        );

        payments[paymentId] = Payment({
            customer: _customer,
            merchant: _merchant,
            amount: _amount,
            token: _token,
            timestamp: block.timestamp,
            note: _note
        });

        paymentIds.push(paymentId);
        customerPayments[_customer].push(paymentId);
        merchantPayments[_merchant].push(paymentId);

        return paymentId;
    }

    /**
     * @dev Get payment details
     */
    function getPayment(bytes32 _paymentId)
        external
        view
        returns (
            address customer,
            address merchant,
            uint256 amount,
            address token,
            uint256 timestamp,
            string memory note
        )
    {
        Payment memory payment = payments[_paymentId];
        return (
            payment.customer,
            payment.merchant,
            payment.amount,
            payment.token,
            payment.timestamp,
            payment.note
        );
    }

    /**
     * @dev Get customer's payment history
     */
    function getCustomerPayments(address _customer)
        external
        view
        returns (bytes32[] memory)
    {
        return customerPayments[_customer];
    }

    /**
     * @dev Get merchant's payment history
     */
    function getMerchantPayments(address _merchant)
        external
        view
        returns (bytes32[] memory)
    {
        return merchantPayments[_merchant];
    }

    /**
     * @dev Get total number of payments
     */
    function getPaymentCount() external view returns (uint256) {
        return paymentIds.length;
    }
}
