// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LoanEscrow
 * @dev Manage loans with NFT collateral
 */
contract LoanEscrow is Ownable, ReentrancyGuard {
    IERC20 public cUSDToken;

    enum LoanStatus {
        Pending,
        Active,
        Repaid,
        Defaulted,
        Cancelled
    }

    struct Loan {
        address borrower;
        address lender;
        uint256 amount;
        uint256 interestRate; // in basis points (e.g., 500 = 5%)
        uint256 duration; // in days
        uint256 startTime;
        uint256 dueDate;
        LoanStatus status;
        address nftContract;
        uint256 nftTokenId;
        bool hasCollateral;
    }

    mapping(bytes32 => Loan) public loans;
    bytes32[] public loanIds;
    
    mapping(address => bytes32[]) public borrowerLoans;
    mapping(address => bytes32[]) public lenderLoans;

    event LoanRequested(
        bytes32 indexed loanId,
        address indexed borrower,
        uint256 amount,
        uint256 interestRate,
        uint256 duration
    );

    event LoanFunded(
        bytes32 indexed loanId,
        address indexed lender,
        uint256 amount
    );

    event LoanRepaid(
        bytes32 indexed loanId,
        address indexed borrower,
        uint256 totalAmount
    );

    event LoanDefaulted(bytes32 indexed loanId);
    event CollateralClaimed(bytes32 indexed loanId, address indexed lender);

    constructor(address _cUSDToken) Ownable(msg.sender) {
        cUSDToken = IERC20(_cUSDToken);
    }

    /**
     * @dev Request a loan without collateral
     */
    function requestLoan(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _durationDays
    ) external returns (bytes32) {
        require(_amount > 0, "Loan amount must be greater than 0");
        require(_durationDays > 0, "Duration must be greater than 0");

        bytes32 loanId = _createLoan(
            msg.sender,
            _amount,
            _interestRate,
            _durationDays,
            address(0),
            0,
            false
        );

        emit LoanRequested(loanId, msg.sender, _amount, _interestRate, _durationDays);
        return loanId;
    }

    /**
     * @dev Request a loan with NFT collateral
     */
    function requestLoanWithCollateral(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _durationDays,
        address _nftContract,
        uint256 _nftTokenId
    ) external returns (bytes32) {
        require(_amount > 0, "Loan amount must be greater than 0");
        require(_durationDays > 0, "Duration must be greater than 0");
        require(_nftContract != address(0), "Invalid NFT contract");

        // Transfer NFT to escrow
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _nftTokenId);

        bytes32 loanId = _createLoan(
            msg.sender,
            _amount,
            _interestRate,
            _durationDays,
            _nftContract,
            _nftTokenId,
            true
        );

        emit LoanRequested(loanId, msg.sender, _amount, _interestRate, _durationDays);
        return loanId;
    }

    /**
     * @dev Internal function to create loan
     */
    function _createLoan(
        address _borrower,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _durationDays,
        address _nftContract,
        uint256 _nftTokenId,
        bool _hasCollateral
    ) internal returns (bytes32) {
        bytes32 loanId = keccak256(
            abi.encodePacked(
                _borrower,
                _amount,
                block.timestamp,
                loanIds.length
            )
        );

        loans[loanId] = Loan({
            borrower: _borrower,
            lender: address(0),
            amount: _amount,
            interestRate: _interestRate,
            duration: _durationDays,
            startTime: 0,
            dueDate: 0,
            status: LoanStatus.Pending,
            nftContract: _nftContract,
            nftTokenId: _nftTokenId,
            hasCollateral: _hasCollateral
        });

        loanIds.push(loanId);
        borrowerLoans[_borrower].push(loanId);

        return loanId;
    }

    /**
     * @dev Fund a loan (become the lender)
     */
    function fundLoan(bytes32 _loanId) external nonReentrant {
        Loan storage loan = loans[_loanId];
        require(loan.status == LoanStatus.Pending, "Loan not available");
        require(msg.sender != loan.borrower, "Cannot fund your own loan");

        // Transfer cUSD from lender to borrower
        bool success = cUSDToken.transferFrom(msg.sender, loan.borrower, loan.amount);
        require(success, "cUSD transfer failed");

        // Update loan
        loan.lender = msg.sender;
        loan.status = LoanStatus.Active;
        loan.startTime = block.timestamp;
        loan.dueDate = block.timestamp + (loan.duration * 1 days);

        lenderLoans[msg.sender].push(_loanId);

        emit LoanFunded(_loanId, msg.sender, loan.amount);
    }

    /**
     * @dev Repay a loan
     */
    function repayLoan(bytes32 _loanId) external nonReentrant {
        Loan storage loan = loans[_loanId];
        require(loan.status == LoanStatus.Active, "Loan not active");
        require(msg.sender == loan.borrower, "Only borrower can repay");

        // Calculate total repayment (principal + interest)
        uint256 interest = (loan.amount * loan.interestRate) / 10000;
        uint256 totalRepayment = loan.amount + interest;

        // Transfer cUSD from borrower to lender
        bool success = cUSDToken.transferFrom(msg.sender, loan.lender, totalRepayment);
        require(success, "cUSD transfer failed");

        // Return NFT collateral if exists
        if (loan.hasCollateral) {
            IERC721(loan.nftContract).transferFrom(
                address(this),
                loan.borrower,
                loan.nftTokenId
            );
        }

        loan.status = LoanStatus.Repaid;

        emit LoanRepaid(_loanId, msg.sender, totalRepayment);
    }

    /**
     * @dev Claim collateral on defaulted loan (lender only)
     */
    function claimCollateral(bytes32 _loanId) external nonReentrant {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.lender, "Only lender can claim");
        require(loan.status == LoanStatus.Active, "Loan not active");
        require(block.timestamp > loan.dueDate, "Loan not yet due");
        require(loan.hasCollateral, "No collateral to claim");

        // Transfer NFT to lender
        IERC721(loan.nftContract).transferFrom(
            address(this),
            loan.lender,
            loan.nftTokenId
        );

        loan.status = LoanStatus.Defaulted;

        emit LoanDefaulted(_loanId);
        emit CollateralClaimed(_loanId, loan.lender);
    }

    /**
     * @dev Get loan details
     */
    function getLoan(bytes32 _loanId)
        external
        view
        returns (
            address borrower,
            address lender,
            uint256 amount,
            uint256 interestRate,
            uint256 duration,
            uint256 dueDate,
            LoanStatus status,
            bool hasCollateral
        )
    {
        Loan memory loan = loans[_loanId];
        return (
            loan.borrower,
            loan.lender,
            loan.amount,
            loan.interestRate,
            loan.duration,
            loan.dueDate,
            loan.status,
            loan.hasCollateral
        );
    }

    /**
     * @dev Get all pending loans
     */
    function getPendingLoans() external view returns (bytes32[] memory) {
        uint256 pendingCount = 0;
        for (uint256 i = 0; i < loanIds.length; i++) {
            if (loans[loanIds[i]].status == LoanStatus.Pending) {
                pendingCount++;
            }
        }

        bytes32[] memory pendingLoans = new bytes32[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < loanIds.length; i++) {
            if (loans[loanIds[i]].status == LoanStatus.Pending) {
                pendingLoans[index] = loanIds[i];
                index++;
            }
        }

        return pendingLoans;
    }

    /**
     * @dev Get borrower's loans
     */
    function getBorrowerLoans(address _borrower)
        external
        view
        returns (bytes32[] memory)
    {
        return borrowerLoans[_borrower];
    }

    /**
     * @dev Get lender's loans
     */
    function getLenderLoans(address _lender)
        external
        view
        returns (bytes32[] memory)
    {
        return lenderLoans[_lender];
    }
}
