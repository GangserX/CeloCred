# 🏗️ CeloCred Complete Architecture Analysis

**Generated:** October 26, 2025  
**Purpose:** Comprehensive mapping of all app components, smart contract integrations, Firebase operations, and blockchain data fetching

---

## 📑 Table of Contents

1. [Smart Contract Integrations](#1-smart-contract-integrations)
2. [Firebase Integrations](#2-firebase-integrations)
3. [Backend Connections](#3-backend-connections)
4. [Chain Data Fetching](#4-chain-data-fetching)
5. [Data Flow Diagram](#5-data-flow-diagram)
6. [Gaps & Recommendations](#6-gaps--recommendations)

---

## 1. 🔗 SMART CONTRACT INTEGRATIONS

### 📋 Overview
- **Total Contracts:** 4
- **Network:** Celo Alfajores Testnet (Chain ID: 44787)
- **RPC:** https://alfajores-forno.celo-testnet.org
- **Wallet Integration:** WalletConnect (Reown AppKit)

### A. MerchantRegistry Contract

**Address:** `0x426f022Ce669Ba1322DD19aD40102bB446428C3b`

#### Flutter Integration:
| Function | File | Method | Status |
|----------|------|--------|--------|
| `registerMerchant()` | `contract_service.dart` | `registerMerchant()` | ✅ WORKING |
| `getMerchant()` | `contract_service.dart` | `getMerchant()` | ✅ WORKING |
| `isMerchant()` | `contract_service.dart` | `isMerchant()` | ✅ WORKING |
| `recordTransaction()` | PaymentProcessor | *Auto-called* | ✅ UPDATED |

#### App Screens Using This Contract:
1. **merchant_onboarding_screen.dart**
   - Line 810: Calls `registerMerchant()` during onboarding
   - User flow: Business info → WalletConnect approval → On-chain registration
   
2. **wallet_provider.dart**
   - Line (various): Calls `isMerchant()` to check merchant status
   - Auto-refreshes on wallet connection

3. **manual_payment_screen.dart**
   - Line (various): Validates merchant address via `isMerchant()`

#### Data Flow:
```
User fills onboarding form
    ↓
MerchantProfile created (Firebase model)
    ↓
registerMerchant() called
    ↓
Data encoded: businessName, category, location
    ↓
AppKitService sends transaction via WalletConnect
    ↓
User approves in Valora/MetaMask
    ↓
Transaction mined on Alfajores
    ↓
Merchant record on-chain ✅
    ↓
Additional data saved to Firebase (emails, phone, logo, etc.)
```

---

### B. PaymentProcessor Contract

**Address:** `0xdB4025CC370DCF0B47db1Aeb9123D206d30F0776`

#### Flutter Integration:
| Function | File | Method | Status |
|----------|------|--------|--------|
| `payWithCELO()` | `contract_service.dart` | `payWithCELO()` | ✅ WORKING |
| `payWithCUSD()` | `contract_service.dart` | `payWithCUSD()` | ✅ WORKING |
| `approveCUSD()` | `contract_service.dart` | `approveCUSDForPayment()` | ✅ WORKING |

#### App Screens Using This Contract:
1. **payment_confirmation_screen.dart**
   - Lines 200-250: Payment UI with CELO/cUSD selection
   - Lines 300-400: Handles 2-step cUSD flow (approve → pay)
   
2. **manual_payment_screen.dart**
   - Quick pay with merchant address input

#### Payment Flows:

**CELO Payment (1 transaction):**
```dart
// payment_confirmation_screen.dart:350
await contractService.payWithCELO(
  merchantAddress: merchantWallet,
  amount: amount,
  note: note ?? '',
);

Flow:
User taps "Pay with CELO"
    ↓
ContractService.payWithCELO()
    ↓
Encodes: merchant address, amount (in Wei), note
    ↓
WalletConnect shows transaction
    ↓
Native CELO transferred
    ↓
MerchantRegistry.recordTransaction() auto-called ✅
    ↓
Payment complete
```

**cUSD Payment (2 transactions):**
```dart
// payment_confirmation_screen.dart:380
// Step 1: Approve cUSD
await contractService.approveCUSDForPayment(amount);

// Step 2: Execute payment
await contractService.payWithCUSD(
  merchantAddress: merchantWallet,
  amount: amount,
  note: note ?? '',
);

Flow:
User taps "Pay with cUSD"
    ↓
Step 1: Approve cUSD spending
    ↓
User approves in wallet (1st tx)
    ↓
Step 2: Execute payment
    ↓
User approves in wallet (2nd tx)
    ↓
cUSD transferred
    ↓
MerchantRegistry.recordTransaction() auto-called ✅
    ↓
Payment complete
```

#### **🆕 Updated Integration (Task 1-2):**
- PaymentProcessor now imports `IMerchantRegistry` interface
- Automatically calls `recordTransaction()` after each payment
- Merchant stats (totalTransactions, totalVolume) updated on-chain
- Authorization system ensures only PaymentProcessor can record transactions

---

### C. LoanEscrow Contract

**Address:** `0x478901c6C7FF4De14B5E8D0EDf6073da918eD742`

#### Flutter Integration:
| Function | File | Method | Status |
|----------|------|--------|--------|
| `requestLoan()` | `contract_service.dart` | `requestLoan()` | ✅ WORKING |
| `requestLoanWithCollateral()` | `contract_service.dart` | `requestLoanWithCollateral()` | ✅ ADDED (Task 7) |
| `fundLoan()` | `contract_service.dart` | `fundLoan()` | ✅ ADDED (Task 5) |
| `repayLoan()` | `contract_service.dart` | `repayLoan()` | ✅ ADDED (Task 6) |
| `approveCUSDForLoan()` | `contract_service.dart` | `approveCUSDForLoan()` | ✅ ADDED |
| `getPendingLoans()` | `contract_service.dart` | Not implemented | ⚠️ TODO |

#### App Screens Using This Contract:

**1. loan_request_screen.dart** - Request loans
```dart
// Line 40: Loads credit score from oracle
final scoreData = await _contractService.getCreditScore(walletAddress);

// Line 560: Conditional loan request
if (_useNFTCollateral && _selectedNFTId != null) {
  // NFT-backed loan
  txHash = await _contractService.requestLoanWithCollateral(
    amount: amount,
    interestRate: interestRateBasisPoints,
    durationDays: _selectedTerm,
    nftContractAddress: nftContractAddress,
    nftTokenId: tokenId,
  );
} else {
  // Regular loan
  txHash = await _contractService.requestLoan(
    amount: amount,
    interestRate: interestRateBasisPoints,
    durationDays: _selectedTerm,
  );
}
```

**2. loan_detail_screen.dart** - Fund loans
```dart
// Lines 500-650: Fund loan button and dialog
await _contractService.approveCUSDForLoan(amount); // Step 1
await _contractService.fundLoan(loanId: widget.loanId); // Step 2

Flow:
Lender views loan in marketplace
    ↓
Taps "Fund This Loan"
    ↓
Enters funding amount
    ↓
Step 1: Approve cUSD (WalletConnect tx 1)
    ↓
Step 2: Fund loan (WalletConnect tx 2)
    ↓
Loan status updated to "funded"
```

**3. loan_repayment_screen.dart** - Repay loans
```dart
// Lines 400-500: Repayment flow
await _contractService.approveCUSDForLoan(totalRepayment); // Step 1
await _contractService.repayLoan(loanId: loan.id); // Step 2

Flow:
Borrower sees "Repay" button in dashboard
    ↓
Views loan details (principal + interest)
    ↓
Taps "Repay Loan"
    ↓
Step 1: Approve cUSD for repayment amount
    ↓
Step 2: Repay loan
    ↓
If NFT collateral → Returned to borrower
    ↓
Loan closed ✅
```

**4. merchant_dashboard_screen.dart** - View active loans
```dart
// Lines 820-850: Query active loans from Firebase
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('loans')
    .where('merchantWallet', isEqualTo: walletAddress)
    .where('status', whereIn: [LoanStatus.approved.name, LoanStatus.disbursed.name])
    .snapshots(),
```

#### **🆕 Complete Loan Lifecycle:**
```
1. REQUEST (loan_request_screen.dart)
   → requestLoan() or requestLoanWithCollateral()
   → Loan created on-chain
   
2. FUND (loan_detail_screen.dart)
   → fundLoan()
   → Lender's cUSD locked in contract
   
3. DISBURSE (automatic)
   → Contract transfers funds to borrower
   
4. REPAY (loan_repayment_screen.dart)
   → repayLoan()
   → Principal + interest returned to lender
   → NFT collateral returned (if any)
   
5. DEFAULT (if not repaid)
   → claimCollateral()
   → Lender receives NFT
```

---

### D. CreditScoreOracle Contract

**Address:** `0x62468b565962f7713f939590B819AFDB5177bD08`

#### Flutter Integration:
| Function | File | Method | Status |
|----------|------|--------|--------|
| `getCreditScore()` | `contract_service.dart` | `getCreditScore()` | ✅ WORKING |
| `updateCreditScore()` | Backend only | Not in app | ⚠️ Backend service needed |
| `updateCreditScoresBatch()` | Backend only | Not in app | ⚠️ Backend service needed |

#### App Screens Using This Contract:

**1. loan_request_screen.dart** - Loads credit score
```dart
// Lines 39-76: Load credit score on screen init
Future<void> _loadCreditScore() async {
  final scoreData = await _contractService.getCreditScore(walletAddress);
  final scoreValue = scoreData['score'] as int?;
  final exists = scoreData['exists'] as bool? ?? false;
  
  if (exists && scoreValue != null && scoreValue > 0) {
    // Use on-chain score
    _creditScore = scoreValue;
    _maxLoanAmount = _calculateMaxLoan(scoreValue);
  } else {
    // Fallback to calculated score
    _creditScore = 650; // Default for new users
  }
}
```

**2. credit_score_detail_screen.dart** - Display score
```dart
// Fetches and displays credit score with breakdown
// Shows "Blockchain Verified" badge if score exists on-chain
```

#### **🆕 Multi-Oracle Support (Task 3):**
```solidity
// CreditScoreOracle.sol - UPDATED
mapping(address => bool) public authorizedOracles;

function setOracle(address _oracle, bool _authorized) external onlyOwner {
  authorizedOracles[_oracle] = _authorized;
}

function updateCreditScore(address _user, uint256 _score) external {
  require(
    authorizedOracles[msg.sender] || msg.sender == owner(),
    "Not authorized"
  );
  // Update score...
}

function updateCreditScoresBatch(
  address[] calldata _users,
  uint256[] calldata _scores
) external {
  require(authorizedOracles[msg.sender], "Not authorized");
  // Batch update for efficiency
}
```

#### Credit Score Flow:
```
App requests credit score (read-only)
    ↓
contractService.getCreditScore(address)
    ↓
Web3Client.call() - No gas needed
    ↓
Returns: {score: 750, lastUpdated: 1698000000, exists: true}
    ↓
Display in UI

⚠️ UPDATES NOT IMPLEMENTED:
Backend oracle service needed to:
- Calculate scores from transaction history
- Call updateCreditScore() with authorized oracle key
- Batch update multiple users efficiently
```

---

## 2. 🔥 FIREBASE INTEGRATIONS

### 📋 Overview
- **Service:** Firebase Cloud Firestore + Firebase Storage
- **Main File:** `lib/core/services/firebase_service.dart` (330+ lines)
- **Initialization:** `lib/main.dart` line 30

### A. Collections Structure

#### 1. **merchants** Collection
```dart
// Document ID: walletAddress (lowercase)
{
  walletAddress: string,
  businessName: string,
  businessCategory: string,
  businessDescription: string,
  location: string,
  contactPhone: string,
  contactEmail: string,
  logoUrl: string?,
  kycStatus: 'pending' | 'approved' | 'rejected',
  registeredAt: Timestamp,
  lastUpdated: Timestamp,
  isActive: boolean
}
```

**CRUD Operations:**
| Operation | Method | Used In | Purpose |
|-----------|--------|---------|---------|
| Create | `registerMerchant()` | `merchant_onboarding_screen.dart` | Store extended merchant details |
| Read | `getMerchantProfile()` | `merchant_dashboard_screen.dart` | Load merchant info |
| Update | `updateMerchantProfile()` | Profile edit screens | Update merchant info |
| Query | `getAllMerchants()` | Marketplace | List all merchants |
| Query | `searchMerchantsByCategory()` | Search/filter | Find merchants by category |

**Data Flow Example:**
```dart
// merchant_onboarding_screen.dart:820
// Step 1: Register on blockchain
final txHash = await contractService.registerMerchant(
  businessName: merchantProfile.businessName,
  category: merchantProfile.businessCategory,
  location: merchantProfile.location,
);

// Step 2: Save to Firebase (extended data)
await FirebaseService.instance.registerMerchant(merchantProfile);

Why both?
- Blockchain: Core data (businessName, category, location)
- Firebase: Extended data (email, phone, logo, description, KYC status)
```

---

#### 2. **transactions** Collection
```dart
// Document ID: auto-generated
{
  merchantAddress: string (lowercase),
  customerAddress: string (lowercase),
  amount: number,
  currency: 'CELO' | 'cUSD' | 'cEUR',
  txHash: string,
  timestamp: Timestamp,
  notes: string?,
  status: 'confirmed' | 'pending' | 'failed',
  type: 'payment' | 'loanDisbursement' | 'loanRepayment'
}
```

**CRUD Operations:**
| Operation | Method | Used In | Purpose |
|-----------|--------|---------|---------|
| Create | `recordTransaction()` | After blockchain payment | Store payment metadata |
| Query | `getMerchantTransactions()` | `merchant_dashboard_screen.dart` | Load transaction history |
| Query | `getMerchantStats()` | `merchant_dashboard_screen.dart` | Calculate revenue stats |

**Data Flow:**
```dart
// payment_confirmation_screen.dart:450
// Step 1: Payment on blockchain
final txHash = await contractService.payWithCUSD(
  merchantAddress: merchantWallet,
  amount: amount,
  note: note,
);

// Step 2: Record in Firebase
await FirebaseService.instance.recordTransaction(
  merchantAddress: merchantWallet,
  customerAddress: walletAddress,
  amount: amount,
  currency: 'cUSD',
  txHash: txHash,
  notes: note,
);

Why Firebase?
- Blockchain stores: from, to, amount (immutable)
- Firebase stores: notes, timestamp, merchant/customer metadata (queryable)
- Firebase enables: transaction history, revenue stats, filtering
```

---

#### 3. **loans** Collection
```dart
// Document ID: auto-generated
{
  id: string,
  merchantId: string,
  merchantWallet: string (lowercase),
  amount: number,
  interestRate: number,
  termDays: number,
  purpose: 'inventory' | 'equipment' | 'marketing' | 'expansion' | 'other',
  purposeNote: string?,
  status: 'draft' | 'pending' | 'approved' | 'disbursed' | 'funded' | 'repaying' | 'repaid' | 'defaulted',
  requestedAt: Timestamp,
  approvedAt: Timestamp?,
  disbursedAt: Timestamp?,
  dueDate: Timestamp?,
  totalRepaymentAmount: number,
  paidAmount: number,
  hasCollateral: boolean,
  nftCollateralId: string?,
  autoRepaymentEnabled: boolean,
  autoRepaymentPercentage: number,
  creditScoreAtRequest: number?,
  lenderAddresses: string[],
  lenderContributions: Map<string, number>,
  rejectionReason: string?
}
```

**CRUD Operations:**
| Operation | Method | Used In | Purpose |
|-----------|--------|---------|---------|
| Query (Stream) | `_getActiveLoansStream()` | `merchant_dashboard_screen.dart` | Real-time active loans |
| Read | `Loan.fromFirestore()` | Various loan screens | Parse loan documents |

**Query Example:**
```dart
// merchant_dashboard_screen.dart:830
Stream<QuerySnapshot> _getActiveLoansStream() {
  return FirebaseFirestore.instance
    .collection('loans')
    .where('merchantWallet', isEqualTo: walletAddress)
    .where('status', whereIn: [
      LoanStatus.approved.name,    // 'approved'
      LoanStatus.disbursed.name,   // 'disbursed'
    ])
    .orderBy('requestedAt', descending: true)
    .snapshots();  // Real-time updates!
}

// Used in StreamBuilder:
StreamBuilder<QuerySnapshot>(
  stream: _getActiveLoansStream(),
  builder: (context, snapshot) {
    final loans = snapshot.data!.docs
      .map((doc) => Loan.fromFirestore(doc))
      .toList();
    
    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (context, index) => _buildLoanCard(loans[index]),
    );
  },
)
```

**Why Firebase for Loans?**
- Blockchain stores: Core loan data (amount, rate, duration, status)
- Firebase stores: Extended metadata (purpose, notes, lenders list, auto-repayment settings)
- Firebase enables: Real-time queries, status filtering, lender tracking

---

#### 4. **creditScores** Collection
```dart
// Document ID: walletAddress (lowercase)
{
  walletAddress: string,
  score: number (300-850),
  factors: {
    paymentHistory: number,
    creditUtilization: number,
    lengthOfHistory: number,
    newCredit: number,
    creditMix: number
  },
  calculatedAt: Timestamp,
  lastUpdated: Timestamp
}
```

**CRUD Operations:**
| Operation | Method | Used In | Purpose |
|-----------|--------|---------|---------|
| Read | `getCreditScore()` | `merchant_dashboard_screen.dart` | Display calculated score |
| Create/Update | `saveCreditScore()` | Backend service | Store calculated score |

**Dual Storage Strategy:**
```
Firebase creditScores:
- Stores: Calculated score + breakdown factors
- Updates: After each transaction (via backend job)
- Purpose: Fast queries, historical tracking

Blockchain CreditScoreOracle:
- Stores: Verified score (set by oracle)
- Updates: Manual or via authorized oracle
- Purpose: Trustless verification, loan approval

Priority:
1. Check blockchain (getCreditScore)
2. If exists → use blockchain score
3. Else → use Firebase calculated score
4. Display source: "Blockchain Verified" or "Calculated"
```

---

#### 5. **userPreferences** Collection
```dart
// Document ID: walletAddress (lowercase)
{
  walletAddress: string,
  theme: 'light' | 'dark' | 'system',
  currency: 'CELO' | 'cUSD' | 'cEUR',
  language: 'en' | 'es' | 'pt',
  notifications: {
    payments: boolean,
    loans: boolean,
    creditScore: boolean
  },
  lastLogin: Timestamp
}
```

**CRUD Operations:**
| Operation | Method | Used In | Purpose |
|-----------|--------|---------|---------|
| Read | `getUserPreferences()` | App initialization | Load user settings |
| Update | `saveUserPreferences()` | Settings screen | Save preferences |
| Update | `updateLastLogin()` | `main.dart` | Track last login |

---

### B. Firebase Storage

**Structure:**
```
/merchant_logos/
  ├── 0x1234...abcd.jpg
  ├── 0x5678...efgh.jpg
  └── ...

/nft_images/  (if implemented)
  ├── contract_0x1234_token_1.jpg
  └── ...
```

**Upload Method:**
```dart
// firebase_service.dart:191
Future<String?> uploadMerchantLogo(String walletAddress, String filePath) async {
  final ref = _storage.ref().child('merchant_logos/${walletAddress.toLowerCase()}.jpg');
  await ref.putFile(filePath as dynamic);
  final url = await ref.getDownloadURL();
  return url;
}
```

---

### C. Firebase vs Blockchain Decision Matrix

| Data Type | Blockchain | Firebase | Reason |
|-----------|-----------|----------|--------|
| **Merchant Core Data** | ✅ Yes | ✅ Yes | Blockchain = trustless verification, Firebase = extended metadata |
| **Payment Amounts** | ✅ Yes | ⚠️ Metadata only | Blockchain = source of truth, Firebase = notes & filtering |
| **Loan Terms** | ✅ Yes | ✅ Yes | Blockchain = immutable terms, Firebase = status tracking |
| **Credit Scores** | ✅ Yes (verified) | ✅ Yes (calculated) | Blockchain = oracle-verified, Firebase = real-time calculation |
| **Transaction History** | ✅ Yes (events) | ✅ Yes (documents) | Blockchain = events (hard to query), Firebase = queryable history |
| **User Preferences** | ❌ No | ✅ Yes | No need for blockchain (not trustless) |
| **Profile Images** | ❌ No | ✅ Yes | Too expensive on blockchain |
| **KYC Documents** | ❌ No | ✅ Yes (Storage) | Privacy & cost |

---

## 3. 🔌 BACKEND CONNECTIONS

### Current Status: ⚠️ **NO DEDICATED BACKEND SERVER**

The app uses **direct integrations only**:

#### A. Direct Blockchain Connection
```dart
// lib/core/services/contract_service.dart
Web3Client _client = Web3Client(
  'https://alfajores-forno.celo-testnet.org',  // Direct RPC
  http.Client()
);

// No backend proxy
// No API gateway
// Direct smart contract calls
```

**Pros:**
- ✅ Fully decentralized
- ✅ No single point of failure
- ✅ Lower latency (no proxy)

**Cons:**
- ❌ RPC rate limits
- ❌ No transaction caching
- ❌ No event indexing

---

#### B. Direct Firebase Connection
```dart
// lib/core/services/firebase_service.dart
FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseStorage _storage = FirebaseStorage.instance;

// Direct Firebase SDK
// No backend API layer
// Client-side Firebase rules enforce security
```

**Security Rules (inferred):**
```javascript
// Firestore Rules (should be configured)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Merchants: Only owner can write
    match /merchants/{walletAddress} {
      allow read: if true;  // Public read
      allow write: if request.auth != null && 
                      request.auth.token.address == walletAddress;
    }
    
    // Transactions: Anyone can write (after blockchain confirmation)
    match /transactions/{txId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    
    // Loans: Owner can read/write
    match /loans/{loanId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

#### C. WalletConnect Bridge
```dart
// lib/core/services/appkit_service.dart
final _appKit = ReownAppKit(
  core: ReownCore(
    projectId: '3c0b3c8951e39b0bf9a0d9a8c89fe1d4',
  ),
);

// WalletConnect bridge servers (Reown hosted)
// User connects → App generates QR/deep link → Wallet scans/opens
// Bridge relays messages between app and wallet
// No custom backend needed
```

---

### 🚨 Missing Backend Components

#### 1. **Credit Score Oracle Backend** ⚠️ CRITICAL
**Current State:** Smart contract exists, but no service to update scores

**What's Needed:**
```javascript
// Node.js Backend Service (Example)
const ethers = require('ethers');
const admin = require('firebase-admin');

// Initialize
const provider = new ethers.JsonRpcProvider('https://alfajores-forno.celo-testnet.org');
const wallet = new ethers.Wallet(process.env.ORACLE_PRIVATE_KEY, provider);
const creditScoreOracle = new ethers.Contract(
  '0x62468b565962f7713f939590B819AFDB5177bD08',
  ABI,
  wallet
);

// Job: Update credit scores every hour
async function updateCreditScores() {
  const merchants = await admin.firestore()
    .collection('merchants')
    .where('isActive', '==', true)
    .get();
  
  for (const doc of merchants.docs) {
    const walletAddress = doc.id;
    
    // Calculate score from Firebase data
    const score = await calculateCreditScore(walletAddress);
    
    // Update on blockchain
    const tx = await creditScoreOracle.updateCreditScore(
      walletAddress,
      score
    );
    await tx.wait();
    
    console.log(`Updated ${walletAddress}: ${score}`);
  }
}

// Run every hour
setInterval(updateCreditScores, 3600000);
```

**Why It's Missing:**
- Requires server infrastructure (Node.js, Docker, etc.)
- Needs secure private key management for oracle wallet
- Costs gas for each score update

**Impact:**
- ⚠️ Credit scores only calculated in Firebase
- ⚠️ Blockchain scores never updated automatically
- ⚠️ Loan approvals rely on Firebase data (not trustless)

---

#### 2. **Event Indexer** ⚠️ RECOMMENDED
**Current State:** Transaction history only in Firebase (manually recorded)

**What's Needed:**
```javascript
// Event Indexer Service
const { EventEmitter } = require('events');

async function indexEvents() {
  // Listen to PaymentProcessor events
  const filter = paymentProcessor.filters.PaymentProcessed();
  
  paymentProcessor.on(filter, async (merchant, customer, amount, event) => {
    // Index to Firebase
    await admin.firestore().collection('transactions').add({
      merchantAddress: merchant.toLowerCase(),
      customerAddress: customer.toLowerCase(),
      amount: ethers.formatEther(amount),
      currency: 'cUSD',
      txHash: event.transactionHash,
      blockNumber: event.blockNumber,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'confirmed'
    });
  });
  
  // Also index: LoanRequested, LoanFunded, LoanRepaid, etc.
}

indexEvents();
```

**Why It's Missing:**
- Requires always-running service
- Needs to handle blockchain reorganizations
- Must track last indexed block

**Impact:**
- ✅ Currently: App manually records transactions in Firebase
- ⚠️ Problem: If app fails to record, transaction lost from history
- ⚠️ Problem: Can't query historical blockchain events easily

---

#### 3. **Transaction Relayer** 🔵 OPTIONAL
**Current State:** Users pay gas directly from their wallets

**What's Needed:**
```javascript
// Meta-Transaction Relayer (Gasless transactions)
async function relayTransaction(req, res) {
  const { signature, functionCall, userAddress } = req.body;
  
  // Verify signature
  const isValid = ethers.verifyMessage(functionCall, signature);
  if (!isValid) return res.status(401).json({ error: 'Invalid signature' });
  
  // Pay gas on behalf of user
  const tx = await contract.connect(relayerWallet)[functionCall.method](
    ...functionCall.params,
    { gasLimit: 300000 }
  );
  
  await tx.wait();
  res.json({ txHash: tx.hash });
}
```

**Why It's Missing:**
- Complex to implement securely
- Requires funding relayer wallet with CELO
- Need anti-spam measures

**Impact:**
- ✅ Currently: Users pay their own gas (more decentralized)
- 🔵 Future: Could enable gasless transactions for better UX

---

## 4. 📡 CHAIN DATA FETCHING

### A. Read Operations (No Gas)

#### Method 1: Direct RPC Calls
```dart
// lib/core/services/contract_service.dart:469
Future<Map<String, dynamic>> getCreditScore(String userAddress) async {
  final function = _creditScoreOracle.function('getCreditScore');
  
  final result = await _client.call(
    contract: _creditScoreOracle,
    function: function,
    params: [EthereumAddress.fromHex(userAddress)],
  );

  return {
    'score': (result[0] as BigInt).toInt(),
    'lastUpdated': (result[1] as BigInt).toInt(),
    'exists': result[2] as bool,
  };
}

Flow:
App calls getCreditScore()
    ↓
Web3Client.call() → HTTP POST to RPC
    ↓
RPC: https://alfajores-forno.celo-testnet.org
    ↓
eth_call (read-only, no tx)
    ↓
Smart contract view function executed
    ↓
Result returned instantly (no gas)
```

**All Read Operations:**
| Function | Contract | Purpose | Used In |
|----------|----------|---------|---------|
| `getMerchant()` | MerchantRegistry | Get merchant details | `manual_payment_screen.dart` |
| `isMerchant()` | MerchantRegistry | Check merchant status | `wallet_provider.dart` |
| `getCreditScore()` | CreditScoreOracle | Get credit score | `loan_request_screen.dart` |
| `getCELOBalance()` | Native | Get CELO balance | `payment_confirmation_screen.dart` |
| `getCUSDBalance()` | cUSD token | Get cUSD balance | `payment_confirmation_screen.dart` |

---

#### Method 2: Firebase Queries (Cached Data)
```dart
// lib/core/services/firebase_service.dart:247
Future<List<Map<String, dynamic>>> getMerchantTransactions(
  String walletAddress, {
  int limit = 100,
}) async {
  final snapshot = await _firestore
    .collection('transactions')
    .where('merchantAddress', isEqualTo: walletAddress.toLowerCase())
    .orderBy('timestamp', descending: true)
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data()).toList();
}

Flow:
App calls getMerchantTransactions()
    ↓
Firestore SDK → HTTP to Firebase servers
    ↓
Query indexed data (fast!)
    ↓
Results returned (no blockchain query needed)
```

**Advantage:**
- ⚡ Much faster than blockchain queries
- 📊 Can filter, sort, paginate easily
- 💰 No gas costs

**Disadvantage:**
- ⚠️ Not the source of truth (blockchain is)
- ⚠️ Requires manual indexing/recording

---

### B. Write Operations (Requires Gas)

#### Transaction Lifecycle:
```dart
// Example: Pay with cUSD
// File: lib/core/services/contract_service.dart:220

// 1. ENCODE transaction data
final function = _paymentProcessor.function('payWithCUSD');
final data = _encodeFunction(function, [
  EthereumAddress.fromHex(merchantAddress),
  amountInWei,
  note,
]);

// 2. SEND via WalletConnect
final txHash = await _appKit.sendTransaction(
  to: CeloConfig.paymentProcessorAddress,
  value: BigInt.zero,
  data: data,
  gas: BigInt.from(300000),
);

Flow:
1. App encodes function call
    ↓
2. App sends to AppKitService
    ↓
3. AppKit sends to WalletConnect bridge
    ↓
4. Bridge relays to user's wallet app
    ↓
5. Wallet shows transaction details
    ↓
6. User approves & signs
    ↓
7. Wallet broadcasts to blockchain
    ↓
8. Transaction mined
    ↓
9. txHash returned to app
```

**All Write Operations:**
| Function | Contract | Gas Cost | Approvals Needed |
|----------|----------|----------|------------------|
| `registerMerchant()` | MerchantRegistry | ~150k gas | 1 (registration) |
| `payWithCELO()` | PaymentProcessor | ~100k gas | 1 (payment) |
| `payWithCUSD()` | PaymentProcessor | ~150k gas | 2 (approve + pay) |
| `requestLoan()` | LoanEscrow | ~200k gas | 1 (request) |
| `requestLoanWithCollateral()` | LoanEscrow | ~400k gas | 2 (NFT approval + request) |
| `fundLoan()` | LoanEscrow | ~180k gas | 2 (cUSD approval + fund) |
| `repayLoan()` | LoanEscrow | ~300k gas | 2 (cUSD approval + repay) |

---

### C. Balance Fetching

```dart
// lib/core/services/web3_service.dart

// CELO Balance (native token)
Future<double> getCELOBalance(String address) async {
  final balance = await _client.getBalance(
    EthereumAddress.fromHex(address)
  );
  return balance.getInWei / BigInt.from(10).pow(18);
}

// cUSD Balance (ERC-20 token)
Future<double> getCUSDBalance(String address) async {
  final function = _cUSD.function('balanceOf');
  final result = await _client.call(
    contract: _cUSD,
    function: function,
    params: [EthereumAddress.fromHex(address)],
  );
  final balance = result[0] as BigInt;
  return balance / BigInt.from(10).pow(18);
}
```

**Used In:**
- `payment_confirmation_screen.dart` - Check if user has enough balance
- `loan_repayment_screen.dart` - Validate repayment amount
- `loan_detail_screen.dart` - Check lender's funding capacity

---

## 5. 🌐 DATA FLOW DIAGRAM

### Payment Flow (End-to-End)
```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                            │
│  payment_confirmation_screen.dart                               │
│  - User enters amount                                           │
│  - Selects CELO or cUSD                                        │
│  - Taps "Pay Now"                                              │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP LAYER                             │
│  contract_service.dart                                          │
│  - Encodes transaction data                                     │
│  - Calculates gas estimate                                      │
│  - Checks user balance                                          │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   WALLETCONNECT LAYER                            │
│  appkit_service.dart + Reown Bridge                             │
│  - Generates signing request                                    │
│  - Sends to wallet via deep link                               │
│  - Waits for user approval                                      │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      USER WALLET                                 │
│  Valora / MetaMask / Other                                      │
│  - Shows transaction details                                    │
│  - User reviews & approves                                      │
│  - Signs with private key                                       │
│  - Broadcasts to blockchain                                     │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CELO BLOCKCHAIN                                │
│  Alfajores Testnet (or Mainnet)                                │
│  - Transaction mined                                            │
│  - PaymentProcessor.payWithCUSD() executed                     │
│  - cUSD transferred to merchant                                 │
│  - MerchantRegistry.recordTransaction() called                 │
│  - Events emitted                                               │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                  POST-TRANSACTION                                │
│  1. App receives txHash                                         │
│  2. firebase_service.dart records transaction                   │
│  3. payment_success_screen.dart shown                           │
│  4. Merchant dashboard updated                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. ⚠️ GAPS & RECOMMENDATIONS

### A. Critical Gaps (Must Fix Before Production)

#### 1. **Smart Contract Redeployment Needed** 🔴
**Affected Contracts:**
- ✅ PaymentProcessor (updated with MerchantRegistry integration)
- ✅ MerchantRegistry (added authorization system)
- ✅ CreditScoreOracle (added multi-oracle support)

**Action Required:**
```bash
cd contracts
npx hardhat run scripts/deploy.js --network alfajores

# Update addresses in:
# lib/core/constants/celo_config.dart
```

---

#### 2. **Credit Score Oracle Backend** 🔴
**Problem:** No service to update credit scores on-chain

**Recommended Solution:**
```javascript
// Backend Service (Node.js + Cloud Functions)
exports.updateCreditScores = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const merchants = await admin.firestore()
      .collection('merchants')
      .where('isActive', '==', true)
      .get();
    
    const updates = [];
    for (const doc of merchants.docs) {
      const score = await calculateScore(doc.id);
      updates.push({ address: doc.id, score });
    }
    
    // Batch update on blockchain
    await creditScoreOracle.updateCreditScoresBatch(
      updates.map(u => u.address),
      updates.map(u => u.score)
    );
  });
```

**Estimated Cost:** ~$50/month (Cloud Functions + gas fees)

---

#### 3. **Transaction History Indexing** 🟡
**Problem:** Relies on manual Firebase recording (can be missed)

**Recommended Solution:**
```javascript
// Event Indexer (Cloud Functions)
exports.indexBlockchainEvents = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const lastBlock = await getLastIndexedBlock();
    const currentBlock = await provider.getBlockNumber();
    
    // Index PaymentProcessed events
    const filter = paymentProcessor.filters.PaymentProcessed();
    const events = await paymentProcessor.queryFilter(
      filter,
      lastBlock + 1,
      currentBlock
    );
    
    for (const event of events) {
      await admin.firestore().collection('transactions').add({
        merchantAddress: event.args.merchant.toLowerCase(),
        customerAddress: event.args.customer.toLowerCase(),
        amount: ethers.formatEther(event.args.amount),
        currency: event.args.currency,
        txHash: event.transactionHash,
        blockNumber: event.blockNumber,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: 'confirmed'
      });
    }
    
    await saveLastIndexedBlock(currentBlock);
  });
```

---

### B. Performance Optimizations

#### 1. **RPC Rate Limiting** 🟡
**Problem:** Direct RPC calls can hit rate limits

**Solution:** Implement RPC caching layer
```dart
// lib/core/services/rpc_cache_service.dart
class RPCCacheService {
  final _cache = <String, dynamic>{};
  final _expiryMap = <String, DateTime>{};
  
  Future<T> cachedCall<T>(
    String key,
    Future<T> Function() call,
    {Duration ttl = const Duration(minutes: 5)}
  ) async {
    if (_cache.containsKey(key)) {
      if (_expiryMap[key]!.isAfter(DateTime.now())) {
        return _cache[key] as T;
      }
    }
    
    final result = await call();
    _cache[key] = result;
    _expiryMap[key] = DateTime.now().add(ttl);
    return result;
  }
}

// Usage:
final score = await rpcCache.cachedCall(
  'credit_score_$address',
  () => contractService.getCreditScore(address),
  ttl: Duration(minutes: 10),
);
```

---

#### 2. **Firebase Composite Indexes** 🟡
**Problem:** Complex queries may be slow

**Create indexes:**
```javascript
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "merchantAddress", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "loans",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "merchantWallet", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "requestedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

### C. Security Enhancements

#### 1. **Firebase Security Rules** 🔴
**Current:** Likely too permissive

**Recommended:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(walletAddress) {
      return isAuthenticated() && 
             request.auth.token.address == walletAddress;
    }
    
    // Merchants: Only owner can update
    match /merchants/{walletAddress} {
      allow read: if true;  // Public read
      allow create: if isAuthenticated();
      allow update: if isOwner(walletAddress);
      allow delete: if false;  // Never delete
    }
    
    // Transactions: Create only after blockchain confirmation
    match /transactions/{txId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
                       resource.data.txHash != null;
      allow update, delete: if false;
    }
    
    // Loans: Only owner can modify
    match /loans/{loanId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.merchantWallet);
      allow delete: if false;
    }
    
    // Credit Scores: Read-only from app
    match /creditScores/{walletAddress} {
      allow read: if true;
      allow write: if false;  // Only backend can write
    }
    
    // User Preferences: Only owner
    match /userPreferences/{walletAddress} {
      allow read, write: if isOwner(walletAddress);
    }
  }
}
```

---

#### 2. **Transaction Verification** 🟡
**Problem:** Firebase transactions not verified against blockchain

**Solution:**
```dart
// Verify transaction before recording
Future<void> recordTransactionSecure({
  required String merchantAddress,
  required String txHash,
  // ... other params
}) async {
  // 1. Fetch transaction from blockchain
  final txReceipt = await _client.getTransactionReceipt(txHash);
  
  // 2. Verify it was successful
  if (txReceipt == null || !txReceipt.status!) {
    throw Exception('Transaction failed or not found');
  }
  
  // 3. Verify it matches our contract
  if (txReceipt.to?.hex.toLowerCase() != 
      CeloConfig.paymentProcessorAddress.toLowerCase()) {
    throw Exception('Transaction not to PaymentProcessor');
  }
  
  // 4. Decode logs to verify merchant address
  final events = txReceipt.logs.where((log) => 
    log.topics[0] == paymentProcessedEventSignature
  );
  
  if (events.isEmpty) {
    throw Exception('PaymentProcessed event not found');
  }
  
  // 5. Now record in Firebase
  await _firestore.collection('transactions').add({
    merchantAddress: merchantAddress.toLowerCase(),
    txHash: txHash,
    verified: true,
    // ...
  });
}
```

---

## 📊 SUMMARY

### Architecture Overview

**Hybrid Approach:**
- ✅ **Blockchain:** Core immutable data (payments, loans, merchant registration)
- ✅ **Firebase:** Extended metadata, queryable history, user preferences
- ✅ **WalletConnect:** Secure transaction signing (no private keys in app)
- ⚠️ **No Backend:** Direct RPC calls (need caching/indexing services)

**Strengths:**
- ✅ Fully decentralized core functionality
- ✅ Fast queries via Firebase
- ✅ Real-time updates with Firestore streams
- ✅ Secure with WalletConnect integration
- ✅ Complete loan lifecycle implemented

**Weaknesses:**
- ⚠️ No credit score automation (oracle backend needed)
- ⚠️ No event indexing (manual Firebase recording)
- ⚠️ RPC rate limiting potential
- ⚠️ Smart contracts need redeployment with updates

**Production Readiness:** 75%
- 🟢 Core functionality: Complete
- 🟢 UI implementation: Complete
- 🟡 Backend services: Missing
- 🟡 Performance optimization: Needed
- 🟡 Security hardening: Recommended

---

**Next Steps:**
1. 🔴 Deploy updated smart contracts
2. 🔴 Implement credit score oracle backend
3. 🟡 Add event indexer service
4. 🟡 Configure Firebase security rules
5. 🟡 Set up RPC caching layer
6. 🔵 Add transaction verification
7. 🔵 Performance testing & optimization

---

**Document Version:** 1.0  
**Last Updated:** October 26, 2025  
**Status:** ✅ Complete
