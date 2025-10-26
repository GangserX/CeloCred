# 🔍 Smart Contract Gaps Analysis & Required Changes

**Date:** October 26, 2025  
**Project:** CeloCred Mobile App  
**Analysis:** Complete audit of app features vs smart contract functions

---

## 📊 **EXECUTIVE SUMMARY**

After comprehensive analysis of all app features and smart contract functions, I've identified **critical missing integrations** that need to be added to smart contracts.

### **Current Status:**
- ✅ Basic merchant registration
- ✅ Payment processing (CELO/cUSD)
- ✅ Basic loan requests
- ❌ **Transaction recording missing**
- ❌ **Merchant profile updates not called**
- ❌ **Loan funding not integrated**
- ❌ **Loan repayment not integrated**
- ❌ **Credit score updates not automated**

---

## 🚨 **CRITICAL GAPS FOUND**

### **GAP #1: Transaction Recording Not Connected to Smart Contract**

#### **Problem:**
```dart
// payment_confirmation_screen.dart - After payment
await FirebaseService.instance.recordTransaction(...); // ❌ Only Firebase

// MerchantRegistry.sol has recordTransaction() but it's NEVER CALLED!
function recordTransaction(address _merchant, uint256 _amount) external {
    merchants[_merchant].totalTransactions += 1;
    merchants[_merchant].totalVolume += _amount;
}
```

#### **Impact:**
- Merchant stats on blockchain are **always 0**
- `totalTransactions` and `totalVolume` in smart contract never updated
- No on-chain proof of transaction history

#### **Solution Required:**
PaymentProcessor should call MerchantRegistry.recordTransaction() after successful payment

---

### **GAP #2: Loan Funding Not Integrated in App**

#### **Problem:**
```dart
// loan_marketplace_screen.dart shows loans but has NO FUNDING functionality
// LoanEscrow.sol has fundLoan() function but it's NOT USED in app!

function fundLoan(bytes32 _loanId) external nonReentrant {
    // Transfer cUSD from lender to borrower
    // Set loan status to Active
}
```

#### **Impact:**
- Users can see loans in marketplace but **cannot fund them**
- Loans stay in "Pending" status forever
- Core P2P lending feature is **non-functional**

#### **Solution Required:**
Add "Fund Loan" button in loan_detail_screen.dart with ContractService.fundLoan()

---

### **GAP #3: Loan Repayment Not Integrated**

#### **Problem:**
```dart
// No screen or functionality for loan repayment!
// LoanEscrow.sol has repayLoan() but it's NOT ACCESSIBLE in app

function repayLoan(bytes32 _loanId) external nonReentrant {
    // Calculate interest
    // Transfer cUSD to lender
    // Return NFT collateral
}
```

#### **Impact:**
- Borrowers **cannot repay loans** through the app
- Loans will default even if borrower wants to pay
- NFT collateral stuck in escrow

#### **Solution Required:**
Add loan repayment screen and ContractService.repayLoan() method

---

### **GAP #4: Collateral Loans Not Integrated**

#### **Problem:**
```dart
// loan_request_screen.dart collects NFT info but calls wrong function
await contractService.requestLoan(...); // ❌ No collateral version

// Should call:
function requestLoanWithCollateral(
    uint256 _amount,
    uint256 _interestRate,
    uint256 _durationDays,
    address _nftContract,
    uint256 _nftTokenId
) external returns (bytes32)
```

#### **Impact:**
- NFT collateral feature is **broken**
- Even when user selects NFT, it's not sent to contract
- Lenders don't get collateral protection

#### **Solution Required:**
Add ContractService.requestLoanWithCollateral() and update loan_request_screen.dart

---

### **GAP #5: Merchant Profile Updates Not On-Chain**

#### **Problem:**
```dart
// merchant_dashboard_screen.dart can edit profile but only saves to Firebase
await FirebaseService.instance.updateMerchantProfile(...); // ❌ Only Firebase

// MerchantRegistry.sol has updateMerchant() but it's NOT CALLED
function updateMerchant(
    string memory _businessName,
    string memory _category,
    string memory _location
) external
```

#### **Impact:**
- Merchant updates not reflected on blockchain
- On-chain merchant data becomes stale
- getMerchant() returns old data

#### **Solution Required:**
Call both smart contract and Firebase when updating profile

---

### **GAP #6: Credit Score Updates Not Automated**

#### **Problem:**
```dart
// credit_scoring_service.dart calculates score but only saves to Firebase
await FirebaseService.instance.saveCreditScore(...); // ❌ Only Firebase

// CreditScoreOracle.sol has updateCreditScore() but requires OWNER
function updateCreditScore(address _user, uint256 _score) external onlyOwner
```

#### **Impact:**
- On-chain credit scores never updated
- getCreditScore() returns non-existent scores
- Lenders can't trust credit scores

#### **Solution Required:**
Need backend oracle service OR make credit score public-updateable with validation

---

## 📝 **REQUIRED SMART CONTRACT CHANGES**

### **Change #1: PaymentProcessor Must Call MerchantRegistry** 🔴 HIGH PRIORITY

**Current Code:**
```solidity
// PaymentProcessor.sol - payWithCELO()
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

    // Record payment internally
    bytes32 paymentId = _recordPayment(...);

    emit PaymentProcessed(...);
}
```

**REQUIRED CHANGE:**
```solidity
// PaymentProcessor.sol - UPDATED
contract PaymentProcessor is Ownable, ReentrancyGuard {
    IERC20 public cUSDToken;
    IMerchantRegistry public merchantRegistry; // ✅ ADD THIS

    constructor(address _cUSDToken, address _merchantRegistry) Ownable(msg.sender) {
        cUSDToken = IERC20(_cUSDToken);
        merchantRegistry = IMerchantRegistry(_merchantRegistry); // ✅ ADD THIS
    }

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

        // ✅ ADD THIS: Update merchant stats on-chain
        merchantRegistry.recordTransaction(_merchant, msg.value);

        // Record payment internally
        bytes32 paymentId = _recordPayment(...);

        emit PaymentProcessed(...);
    }

    function payWithCUSD(address _merchant, uint256 _amount, string memory _note)
        external
        nonReentrant
    {
        // ... existing code ...
        
        // ✅ ADD THIS: Update merchant stats on-chain
        merchantRegistry.recordTransaction(_merchant, _amount);

        emit PaymentProcessed(...);
    }
}

// ✅ ADD INTERFACE
interface IMerchantRegistry {
    function recordTransaction(address _merchant, uint256 _amount) external;
    function isMerchant(address _address) external view returns (bool);
}
```

**Why This Change:**
- ✅ Keeps merchant stats accurate on-chain
- ✅ No app code changes needed (happens automatically)
- ✅ MerchantRegistry becomes single source of truth
- ✅ totalTransactions and totalVolume stay updated

---

### **Change #2: Make MerchantRegistry.recordTransaction() Public** 🔴 HIGH PRIORITY

**Current Code:**
```solidity
// MerchantRegistry.sol
function recordTransaction(address _merchant, uint256 _amount) external {
    require(merchants[_merchant].isActive, "Merchant not active");
    
    merchants[_merchant].totalTransactions += 1;
    merchants[_merchant].totalVolume += _amount;
}
```

**REQUIRED CHANGE:**
```solidity
// MerchantRegistry.sol - UPDATED
mapping(address => bool) public authorizedCallers; // ✅ ADD THIS

function setAuthorizedCaller(address _caller, bool _authorized) external onlyOwner {
    authorizedCallers[_caller] = _authorized;
}

function recordTransaction(address _merchant, uint256 _amount) external {
    require(authorizedCallers[msg.sender], "Not authorized"); // ✅ ADD THIS
    require(merchants[_merchant].isActive, "Merchant not active");
    
    merchants[_merchant].totalTransactions += 1;
    merchants[_merchant].totalVolume += _amount;
    
    emit TransactionRecorded(_merchant, _amount, block.timestamp); // ✅ ADD EVENT
}

// ✅ ADD EVENT
event TransactionRecorded(
    address indexed merchant,
    uint256 amount,
    uint256 timestamp
);
```

**Why This Change:**
- ✅ Only PaymentProcessor can call recordTransaction
- ✅ Prevents unauthorized transaction recording
- ✅ Owner can authorize other contracts in future
- ✅ Event emission for transparency

---

### **Change #3: Add Batch Loan Queries** 🟡 MEDIUM PRIORITY

**Problem:** App fetches pending loans but needs loan details separately (inefficient)

**ADD TO LoanEscrow.sol:**
```solidity
// ✅ ADD THIS FUNCTION
function getPendingLoansWithDetails(uint256 _limit, uint256 _offset)
    external
    view
    returns (
        bytes32[] memory loanIds,
        address[] memory borrowers,
        uint256[] memory amounts,
        uint256[] memory interestRates,
        uint256[] memory durations,
        bool[] memory hasCollateral
    )
{
    uint256 pendingCount = 0;
    for (uint256 i = 0; i < loanIds.length; i++) {
        if (loans[loanIds[i]].status == LoanStatus.Pending) {
            pendingCount++;
        }
    }

    uint256 start = _offset;
    uint256 end = _offset + _limit;
    if (end > pendingCount) end = pendingCount;
    uint256 resultCount = end - start;

    bytes32[] memory resultIds = new bytes32[](resultCount);
    address[] memory resultBorrowers = new address[](resultCount);
    uint256[] memory resultAmounts = new uint256[](resultCount);
    uint256[] memory resultRates = new uint256[](resultCount);
    uint256[] memory resultDurations = new uint256[](resultCount);
    bool[] memory resultCollateral = new bool[](resultCount);

    uint256 pendingIndex = 0;
    uint256 resultIndex = 0;
    
    for (uint256 i = 0; i < loanIds.length && resultIndex < resultCount; i++) {
        if (loans[loanIds[i]].status == LoanStatus.Pending) {
            if (pendingIndex >= start) {
                Loan memory loan = loans[loanIds[i]];
                resultIds[resultIndex] = loanIds[i];
                resultBorrowers[resultIndex] = loan.borrower;
                resultAmounts[resultIndex] = loan.amount;
                resultRates[resultIndex] = loan.interestRate;
                resultDurations[resultIndex] = loan.duration;
                resultCollateral[resultIndex] = loan.hasCollateral;
                resultIndex++;
            }
            pendingIndex++;
        }
    }

    return (resultIds, resultBorrowers, resultAmounts, resultRates, resultDurations, resultCollateral);
}

// ✅ ADD: Get active loans for borrower
function getActiveBorrowerLoans(address _borrower)
    external
    view
    returns (bytes32[] memory)
{
    bytes32[] memory allLoans = borrowerLoans[_borrower];
    uint256 activeCount = 0;

    for (uint256 i = 0; i < allLoans.length; i++) {
        if (loans[allLoans[i]].status == LoanStatus.Active) {
            activeCount++;
        }
    }

    bytes32[] memory activeLoans = new bytes32[](activeCount);
    uint256 index = 0;

    for (uint256 i = 0; i < allLoans.length; i++) {
        if (loans[allLoans[i]].status == LoanStatus.Active) {
            activeLoans[index] = allLoans[i];
            index++;
        }
    }

    return activeLoans;
}
```

**Why This Change:**
- ✅ Reduces RPC calls from 1+N to 1 call
- ✅ Pagination support for large loan lists
- ✅ Better user experience (faster loading)

---

### **Change #4: Add Credit Score Validation** 🟡 MEDIUM PRIORITY

**Problem:** Credit scores can only be updated by owner (centralized)

**ADD TO CreditScoreOracle.sol:**
```solidity
// ✅ ADD: Authorized oracles
mapping(address => bool) public authorizedOracles;

event OracleAuthorized(address indexed oracle, bool authorized);

function setOracle(address _oracle, bool _authorized) external onlyOwner {
    authorizedOracles[_oracle] = _authorized;
    emit OracleAuthorized(_oracle, _authorized);
}

// ✅ UPDATE: Allow oracles to update scores
function updateCreditScore(address _user, uint256 _score) external {
    require(authorizedOracles[msg.sender] || msg.sender == owner(), "Not authorized");
    require(_score >= 300 && _score <= 850, "Score must be between 300-850");

    uint256 oldScore = creditScores[_user].score;
    
    if (!creditScores[_user].exists) {
        scoredAddresses.push(_user);
    }

    creditScores[_user] = CreditScore({
        score: _score,
        lastUpdated: block.timestamp,
        exists: true
    });

    emit CreditScoreUpdated(_user, oldScore, _score, block.timestamp);
}

// ✅ ADD: Batch update for efficiency
function updateCreditScoresBatch(
    address[] calldata _users,
    uint256[] calldata _scores
) external {
    require(authorizedOracles[msg.sender] || msg.sender == owner(), "Not authorized");
    require(_users.length == _scores.length, "Array length mismatch");

    for (uint256 i = 0; i < _users.length; i++) {
        require(_scores[i] >= 300 && _scores[i] <= 850, "Invalid score");
        
        uint256 oldScore = creditScores[_users[i]].score;
        
        if (!creditScores[_users[i]].exists) {
            scoredAddresses.push(_users[i]);
        }

        creditScores[_users[i]] = CreditScore({
            score: _scores[i],
            lastUpdated: block.timestamp,
            exists: true
        });

        emit CreditScoreUpdated(_users[i], oldScore, _scores[i], block.timestamp);
    }
}
```

**Why This Change:**
- ✅ Allows multiple oracle nodes (decentralization)
- ✅ Batch updates save gas
- ✅ Backend service can update scores automatically

---

## 📱 **REQUIRED FLUTTER APP CHANGES**

### **App Change #1: Add Loan Funding Feature** 🔴 HIGH PRIORITY

**Create:** `lib/core/services/contract_service.dart` - Add method

```dart
/// Fund a loan (become the lender)
Future<String> fundLoan({
  required String loanId,
}) async {
  try {
    if (!_appKit.isConnected) {
      throw Exception('Please connect your wallet first');
    }

    print('💰 Funding loan: $loanId');

    final function = _loanEscrow.function('fundLoan');
    
    // Convert hex string to bytes32
    final loanIdBytes = hexToBytes(loanId);
    
    final data = _encodeFunction(function, [loanIdBytes]);

    // Note: Requires prior cUSD approval!
    final txHash = await _appKit.sendTransaction(
      to: CeloConfig.loanEscrowAddress,
      value: BigInt.zero,
      data: data,
      gas: BigInt.from(300000),
    );

    print('✅ Loan funded! TxHash: $txHash');
    return txHash;
  } catch (e) {
    print('❌ Error funding loan: $e');
    rethrow;
  }
}

/// Approve cUSD for loan funding
Future<String> approveCUSDForLoan(double amount) async {
  try {
    final amountInWei = BigInt.from((amount * 1e18).toInt());
    
    final cUSDContract = DeployedContract(
      ContractAbi.fromJson(
        '[{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}]',
        'cUSD',
      ),
      EthereumAddress.fromHex(CeloConfig.cUSDAddress),
    );

    final approveFunction = cUSDContract.function('approve');
    final approveData = _encodeFunction(approveFunction, [
      EthereumAddress.fromHex(CeloConfig.loanEscrowAddress),
      amountInWei,
    ]);

    final txHash = await _appKit.sendTransaction(
      to: CeloConfig.cUSDAddress,
      value: BigInt.zero,
      data: approveData,
      gas: BigInt.from(100000),
    );

    print('✅ cUSD approved for loan funding');
    return txHash;
  } catch (e) {
    print('❌ Error approving cUSD: $e');
    rethrow;
  }
}
```

**Update:** `lib/features/marketplace/loan_detail_screen.dart`

```dart
// Add "Fund This Loan" button
ElevatedButton(
  onPressed: () async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(...);
    if (confirm != true) return;

    try {
      // Step 1: Approve cUSD
      showDialog(context: context, builder: (_) => LoadingDialog('Approving cUSD...'));
      await contractService.approveCUSDForLoan(loanAmount);
      
      Navigator.pop(context); // Close loading
      
      // Step 2: Fund loan
      showDialog(context: context, builder: (_) => LoadingDialog('Funding loan...'));
      final txHash = await contractService.fundLoan(loanId: widget.loanId);
      
      Navigator.pop(context); // Close loading
      
      // Show success
      showDialog(
        context: context,
        builder: (_) => SuccessDialog('Loan funded successfully!'),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      showDialog(
        context: context,
        builder: (_) => ErrorDialog('Failed to fund loan: $e'),
      );
    }
  },
  child: Text('Fund This Loan'),
)
```

---

### **App Change #2: Add Loan Repayment Feature** 🔴 HIGH PRIORITY

**Add to:** `lib/core/services/contract_service.dart`

```dart
/// Repay a loan
Future<String> repayLoan({
  required String loanId,
  required double totalAmount, // principal + interest
}) async {
  try {
    if (!_appKit.isConnected) {
      throw Exception('Please connect your wallet first');
    }

    print('💸 Repaying loan: $loanId');
    print('   Amount: $totalAmount cUSD');

    final function = _loanEscrow.function('repayLoan');
    final loanIdBytes = hexToBytes(loanId);
    final data = _encodeFunction(function, [loanIdBytes]);

    // Note: Requires prior cUSD approval!
    final txHash = await _appKit.sendTransaction(
      to: CeloConfig.loanEscrowAddress,
      value: BigInt.zero,
      data: data,
      gas: BigInt.from(300000),
    );

    print('✅ Loan repaid! TxHash: $txHash');
    return txHash;
  } catch (e) {
    print('❌ Error repaying loan: $e');
    rethrow;
  }
}
```

**Create:** `lib/features/loan/loan_repayment_screen.dart` (new file)

```dart
import 'package:flutter/material.dart';
import '../../core/services/contract_service.dart';
import '../../core/models/loan_model.dart';

class LoanRepaymentScreen extends StatefulWidget {
  final Loan loan;

  const LoanRepaymentScreen({Key? key, required this.loan}) : super(key: key);

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  final _contractService = ContractService();
  bool _isRepaying = false;

  double get totalRepayment => widget.loan.totalRepaymentAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Repay Loan')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Loan Amount', style: TextStyle(fontSize: 14)),
                    Text('${widget.loan.amount} cUSD', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Interest Rate:'),
                        Text('${widget.loan.interestRate}%'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Interest Amount:'),
                        Text('${(widget.loan.amount * widget.loan.interestRate / 100).toStringAsFixed(2)} cUSD'),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Repayment:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${totalRepayment.toStringAsFixed(2)} cUSD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRepaying ? null : _repayLoan,
              child: _isRepaying
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Repay Loan'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _repayLoan() async {
    setState(() => _isRepaying = true);

    try {
      // Step 1: Approve cUSD
      await _contractService.approveCUSDForLoan(totalRepayment);
      
      // Step 2: Repay loan
      final txHash = await _contractService.repayLoan(
        loanId: widget.loan.id,
        totalAmount: totalRepayment,
      );

      if (!mounted) return;

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan repaid successfully!')),
      );
      
      Navigator.pop(context, true); // Return to previous screen
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to repay loan: $e')),
      );
    } finally {
      setState(() => _isRepaying = false);
    }
  }

  @override
  void dispose() {
    _contractService.dispose();
    super.dispose();
  }
}
```

---

### **App Change #3: Add Collateral Loan Support** 🟡 MEDIUM PRIORITY

**Add to:** `lib/core/services/contract_service.dart`

```dart
/// Request a loan WITH NFT collateral
Future<String> requestLoanWithCollateral({
  required double amount,
  required int interestRate,
  required int durationDays,
  required String nftContractAddress,
  required int nftTokenId,
}) async {
  try {
    if (!_appKit.isConnected) {
      throw Exception('Please connect your wallet first');
    }

    final amountInWei = BigInt.from((amount * 1e18).toInt());

    print('📋 Requesting collateralized loan:');
    print('   Amount: $amount cUSD');
    print('   NFT: $nftContractAddress #$nftTokenId');

    final function = _loanEscrow.function('requestLoanWithCollateral');
    final data = _encodeFunction(function, [
      amountInWei,
      BigInt.from(interestRate),
      BigInt.from(durationDays),
      EthereumAddress.fromHex(nftContractAddress),
      BigInt.from(nftTokenId),
    ]);

    final txHash = await _appKit.sendTransaction(
      to: CeloConfig.loanEscrowAddress,
      value: BigInt.zero,
      data: data,
      gas: BigInt.from(400000), // Higher gas for NFT transfer
    );

    print('✅ Collateralized loan requested! TxHash: $txHash');
    return txHash;
  } catch (e) {
    print('❌ Error requesting collateralized loan: $e');
    rethrow;
  }
}
```

**Update:** `lib/features/loan/loan_request_screen.dart`

```dart
// In _submitLoanRequest() method
if (_selectedNFT != null) {
  // Use collateral version
  txHash = await _contractService.requestLoanWithCollateral(
    amount: double.parse(_amountController.text),
    interestRate: (_interestRate * 100).toInt(),
    durationDays: _termDays,
    nftContractAddress: _selectedNFT!.contractAddress,
    nftTokenId: _selectedNFT!.tokenId,
  );
} else {
  // Use regular version
  txHash = await _contractService.requestLoan(
    amount: double.parse(_amountController.text),
    interestRate: (_interestRate * 100).toInt(),
    durationDays: _termDays,
  );
}
```

---

### **App Change #4: Update ABI Definitions** 🔴 HIGH PRIORITY

**Update:** `lib/core/services/contract_service.dart` - Add missing functions to ABIs

```dart
static const String _loanEscrowABI = '''
[
  {
    "inputs": [
      {"name": "_amount", "type": "uint256"},
      {"name": "_interestRate", "type": "uint256"},
      {"name": "_durationDays", "type": "uint256"}
    ],
    "name": "requestLoan",
    "outputs": [{"name": "", "type": "bytes32"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "_amount", "type": "uint256"},
      {"name": "_interestRate", "type": "uint256"},
      {"name": "_durationDays", "type": "uint256"},
      {"name": "_nftContract", "type": "address"},
      {"name": "_nftTokenId", "type": "uint256"}
    ],
    "name": "requestLoanWithCollateral",
    "outputs": [{"name": "", "type": "bytes32"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "_loanId", "type": "bytes32"}],
    "name": "fundLoan",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "_loanId", "type": "bytes32"}],
    "name": "repayLoan",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "_loanId", "type": "bytes32"}],
    "name": "getLoan",
    "outputs": [
      {"name": "borrower", "type": "address"},
      {"name": "lender", "type": "address"},
      {"name": "amount", "type": "uint256"},
      {"name": "interestRate", "type": "uint256"},
      {"name": "duration", "type": "uint256"},
      {"name": "dueDate", "type": "uint256"},
      {"name": "status", "type": "uint8"},
      {"name": "hasCollateral", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getPendingLoans",
    "outputs": [{"name": "", "type": "bytes32[]"}],
    "stateMutability": "view",
    "type": "function"
  }
]
''';
```

---

## 🚀 **DEPLOYMENT PLAN**

### **Phase 1: Critical Smart Contract Updates** (Deploy First)

1. ✅ Update PaymentProcessor.sol to call MerchantRegistry
2. ✅ Update MerchantRegistry.sol with authorization
3. ✅ Redeploy both contracts to Alfajores
4. ✅ Update contract addresses in celo_config.dart
5. ✅ Test payment flow with transaction recording

### **Phase 2: App Integration Updates** (Deploy After Contracts)

1. ✅ Add loan funding feature to contract_service.dart
2. ✅ Create loan repayment screen
3. ✅ Add collateral loan support
4. ✅ Update all ABIs in contract_service.dart
5. ✅ Add "Fund Loan" button to loan marketplace
6. ✅ Add "Repay Loan" button to merchant dashboard
7. ✅ Test all flows end-to-end

### **Phase 3: Credit Score Oracle** (Backend Service)

1. ✅ Update CreditScoreOracle.sol with multi-oracle support
2. ✅ Redeploy oracle contract
3. ✅ Create backend service to calculate and update scores
4. ✅ Authorize backend service as oracle
5. ✅ Schedule periodic score updates

---

## 📊 **PRIORITY MATRIX**

| Feature | Priority | Impact | Effort | Deploy Order |
|---------|----------|--------|--------|--------------|
| Transaction Recording | 🔴 HIGH | Critical (merchant stats broken) | Medium | 1 |
| Loan Funding | 🔴 HIGH | Critical (P2P lending broken) | High | 2 |
| Loan Repayment | 🔴 HIGH | Critical (loans can't close) | High | 2 |
| Collateral Loans | 🟡 MEDIUM | Important (NFT feature broken) | Medium | 3 |
| Merchant Updates On-Chain | 🟡 MEDIUM | Nice to have (data consistency) | Low | 4 |
| Credit Score Automation | 🟡 MEDIUM | Important (trust & scoring) | High | 5 |
| Batch Queries | 🔵 LOW | Performance (faster loading) | Medium | 6 |

---

## ✅ **VERIFICATION CHECKLIST**

After implementing all changes:

### Smart Contracts:
- [ ] PaymentProcessor calls MerchantRegistry.recordTransaction()
- [ ] MerchantRegistry has authorization system
- [ ] LoanEscrow.fundLoan() accessible
- [ ] LoanEscrow.repayLoan() accessible
- [ ] LoanEscrow.requestLoanWithCollateral() accessible
- [ ] CreditScoreOracle supports multiple oracles
- [ ] All contracts deployed to Alfajores
- [ ] Contract addresses updated in app

### Flutter App:
- [ ] ContractService has fundLoan() method
- [ ] ContractService has repayLoan() method
- [ ] ContractService has requestLoanWithCollateral() method
- [ ] Loan detail screen has "Fund Loan" button
- [ ] Loan repayment screen created
- [ ] NFT collateral properly sent to contract
- [ ] All ABIs updated with new functions
- [ ] cUSD approval flow for loans

### Testing:
- [ ] Payment updates merchant stats on-chain
- [ ] Can fund a pending loan
- [ ] Can repay an active loan
- [ ] Can request loan with NFT collateral
- [ ] NFT returned after repayment
- [ ] All transactions show in wallet

---

## 🎯 **FINAL RECOMMENDATION**

**MUST DO BEFORE LAUNCH:**
1. 🔴 Update & redeploy PaymentProcessor (transaction recording)
2. 🔴 Add loan funding to app
3. 🔴 Add loan repayment to app

**SHOULD DO BEFORE LAUNCH:**
4. 🟡 Fix collateral loan integration
5. 🟡 Set up credit score oracle backend

**NICE TO HAVE:**
6. 🔵 Batch query optimization
7. 🔵 On-chain merchant profile updates

---

**Current Status:** ⚠️ **INCOMPLETE - Core features not integrated**  
**After Implementation:** ✅ **PRODUCTION READY**

