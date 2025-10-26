/**
 * Firebase Schema Verification
 * 
 * Ensures backend and app use the same Firebase structure
 */

export const FIREBASE_COLLECTIONS = {
  // Merchant profiles
  MERCHANTS: 'merchants',
  
  // Transaction history
  TRANSACTIONS: 'transactions',
  
  // Loan records
  LOANS: 'loans',
  
  // Credit scores (calculated)
  CREDIT_SCORES: 'creditScores',
  
  // User preferences
  USER_PREFERENCES: 'userPreferences',
};

/**
 * Merchant document structure
 */
export const MerchantSchema = {
  walletAddress: 'string',          // Primary key (lowercase)
  businessName: 'string',
  businessCategory: 'string',
  businessDescription: 'string',
  location: 'string',
  contactPhone: 'string',
  contactEmail: 'string',
  logoUrl: 'string|null',
  kycStatus: 'pending|approved|rejected',
  registeredAt: 'Timestamp',
  lastUpdated: 'Timestamp',
  isActive: 'boolean',
};

/**
 * Transaction document structure
 */
export const TransactionSchema = {
  merchantAddress: 'string',        // lowercase
  customerAddress: 'string',        // lowercase
  amount: 'number',
  currency: 'CELO|cUSD|cEUR',
  txHash: 'string',
  timestamp: 'Timestamp',
  notes: 'string|null',
  status: 'confirmed|pending|failed',
  type: 'payment|loanDisbursement|loanRepayment',
};

/**
 * Loan document structure
 */
export const LoanSchema = {
  id: 'string',
  merchantId: 'string',
  merchantWallet: 'string',         // lowercase
  amount: 'number',
  interestRate: 'number',
  termDays: 'number',
  purpose: 'inventory|equipment|marketing|expansion|other',
  purposeNote: 'string|null',
  status: 'draft|pending|approved|disbursed|funded|repaying|repaid|defaulted',
  requestedAt: 'Timestamp',
  approvedAt: 'Timestamp|null',
  disbursedAt: 'Timestamp|null',
  dueDate: 'Timestamp|null',
  totalRepaymentAmount: 'number',
  paidAmount: 'number',
  hasCollateral: 'boolean',
  nftCollateralId: 'string|null',
  autoRepaymentEnabled: 'boolean',
  autoRepaymentPercentage: 'number',
  creditScoreAtRequest: 'number|null',
  lenderAddresses: 'string[]',
  lenderContributions: 'object',
  rejectionReason: 'string|null',
};

/**
 * Credit score document structure
 */
export const CreditScoreSchema = {
  walletAddress: 'string',          // Primary key (lowercase)
  score: 'number',                  // 300-850
  factors: {
    paymentHistory: 'number',
    creditUtilization: 'number',
    lengthOfHistory: 'number',
    newCredit: 'number',
    creditMix: 'number',
  },
  calculatedAt: 'Timestamp',
  lastUpdated: 'Timestamp',
};

/**
 * Validate merchant data structure
 */
export function validateMerchantData(data) {
  const required = [
    'walletAddress',
    'businessName',
    'businessCategory',
    'location',
    'isActive',
  ];
  
  for (const field of required) {
    if (!(field in data)) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
  
  // Validate wallet address format
  if (!/^0x[a-fA-F0-9]{40}$/.test(data.walletAddress)) {
    throw new Error('Invalid wallet address format');
  }
  
  // Ensure lowercase
  data.walletAddress = data.walletAddress.toLowerCase();
  
  return data;
}

/**
 * Validate transaction data structure
 */
export function validateTransactionData(data) {
  const required = [
    'merchantAddress',
    'customerAddress',
    'amount',
    'currency',
    'txHash',
  ];
  
  for (const field of required) {
    if (!(field in data)) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
  
  // Validate addresses
  if (!/^0x[a-fA-F0-9]{40}$/.test(data.merchantAddress)) {
    throw new Error('Invalid merchant address');
  }
  if (!/^0x[a-fA-F0-9]{40}$/.test(data.customerAddress)) {
    throw new Error('Invalid customer address');
  }
  
  // Ensure lowercase
  data.merchantAddress = data.merchantAddress.toLowerCase();
  data.customerAddress = data.customerAddress.toLowerCase();
  
  // Validate currency
  const validCurrencies = ['CELO', 'cUSD', 'cEUR'];
  if (!validCurrencies.includes(data.currency)) {
    throw new Error(`Invalid currency: ${data.currency}`);
  }
  
  return data;
}

/**
 * Validate credit score data structure
 */
export function validateCreditScoreData(data) {
  const required = ['walletAddress', 'score'];
  
  for (const field of required) {
    if (!(field in data)) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
  
  // Validate score range
  if (data.score < 300 || data.score > 850) {
    throw new Error(`Score out of range (300-850): ${data.score}`);
  }
  
  // Ensure lowercase
  data.walletAddress = data.walletAddress.toLowerCase();
  
  return data;
}

export default {
  FIREBASE_COLLECTIONS,
  MerchantSchema,
  TransactionSchema,
  LoanSchema,
  CreditScoreSchema,
  validateMerchantData,
  validateTransactionData,
  validateCreditScoreData,
};
