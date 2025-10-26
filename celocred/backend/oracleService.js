import { ethers } from 'ethers';
import admin from 'firebase-admin';
import { CreditScoreCalculator } from './creditScoreCalculator.js';
import { config } from './config.js';
import { FIREBASE_COLLECTIONS, validateCreditScoreData } from './firebaseSchema.js';

// CreditScoreOracle ABI (only functions we need)
const CREDIT_SCORE_ORACLE_ABI = [
  'function updateCreditScore(address _user, uint256 _score) external',
  'function updateCreditScoresBatch(address[] calldata _users, uint256[] calldata _scores) external',
  'function getCreditScore(address _user) external view returns (uint256 score, uint256 lastUpdated, bool exists)',
  'function authorizedOracles(address) external view returns (bool)',
];

export class OracleService {
  constructor() {
    this.calculator = new CreditScoreCalculator();
    this.provider = null;
    this.wallet = null;
    this.contract = null;
    this.initialized = false;
  }

  /**
   * Initialize the oracle service
   */
  async initialize() {
    if (this.initialized) {
      console.log('Oracle service already initialized');
      return;
    }

    console.log('Initializing Oracle Service...');

    // Initialize Firebase Admin
    if (!admin.apps.length) {
      const serviceAccount = await import(config.firebaseServiceAccountPath, {
        assert: { type: 'json' }
      });
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount.default),
      });
      
      console.log('✅ Firebase Admin initialized');
    }

    // Initialize Ethers
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
    this.wallet = new ethers.Wallet(config.oraclePrivateKey, this.provider);
    this.contract = new ethers.Contract(
      config.creditScoreOracleAddress,
      CREDIT_SCORE_ORACLE_ABI,
      this.wallet
    );

    console.log(`✅ Connected to Celo network: ${config.rpcUrl}`);
    console.log(`✅ Oracle wallet: ${this.wallet.address}`);

    // Check if wallet is authorized
    const isAuthorized = await this.contract.authorizedOracles(this.wallet.address);
    if (!isAuthorized) {
      console.warn(`⚠️  WARNING: Wallet ${this.wallet.address} is NOT authorized as oracle!`);
      console.warn(`   Run this command with the contract owner wallet:`);
      console.warn(`   setOracle("${this.wallet.address}", true)`);
    } else {
      console.log('✅ Oracle wallet is authorized');
    }

    // Check wallet balance
    const balance = await this.provider.getBalance(this.wallet.address);
    const balanceInCelo = ethers.formatEther(balance);
    console.log(`✅ Wallet balance: ${balanceInCelo} CELO`);

    if (parseFloat(balanceInCelo) < 0.1) {
      console.warn(`⚠️  WARNING: Low balance! Please fund wallet with CELO for gas fees.`);
      console.warn(`   Visit: https://faucet.celo.org/alfajores`);
    }

    this.initialized = true;
    console.log('✅ Oracle Service initialized successfully\n');
  }

  /**
   * Get all active merchants from Firebase
   */
  async getActiveMerchants() {
    const db = admin.firestore();
    const snapshot = await db
      .collection(FIREBASE_COLLECTIONS.MERCHANTS)
      .where('isActive', '==', true)
      .get();

    return snapshot.docs.map(doc => ({
      walletAddress: doc.id,
      ...doc.data(),
    }));
  }

  /**
   * Get merchant transaction history
   */
  async getMerchantTransactions(walletAddress) {
    const db = admin.firestore();
    const snapshot = await db
      .collection(FIREBASE_COLLECTIONS.TRANSACTIONS)
      .where('merchantAddress', '==', walletAddress.toLowerCase())
      .orderBy('timestamp', 'desc')
      .get();

    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Get merchant loan history
   */
  async getMerchantLoans(walletAddress) {
    const db = admin.firestore();
    const snapshot = await db
      .collection(FIREBASE_COLLECTIONS.LOANS)
      .where('merchantWallet', '==', walletAddress.toLowerCase())
      .get();

    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Save calculated credit score to Firebase
   * This allows the app to display calculated scores even if blockchain update fails
   */
  async saveCreditScoreToFirebase(walletAddress, score, breakdown) {
    const db = admin.firestore();
    
    try {
      const scoreData = {
        walletAddress: walletAddress.toLowerCase(),
        score: score,
        factors: breakdown.components,
        calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        metadata: breakdown.metadata,
      };
      
      // Validate data
      validateCreditScoreData(scoreData);
      
      // Save to Firebase
      await db
        .collection(FIREBASE_COLLECTIONS.CREDIT_SCORES)
        .doc(walletAddress.toLowerCase())
        .set(scoreData, { merge: true });
      
      console.log(`  💾 Saved to Firebase: ${walletAddress} = ${score}`);
      return true;
    } catch (error) {
      console.error(`  ❌ Error saving to Firebase:`, error.message);
      return false;
    }
  }

  /**
   * Calculate credit score for a single merchant
   */
  async calculateMerchantScore(walletAddress) {
    console.log(`Calculating score for ${walletAddress}...`);

    // Fetch all data
    const [merchantDoc, transactions, loans] = await Promise.all([
      admin.firestore().collection(FIREBASE_COLLECTIONS.MERCHANTS).doc(walletAddress.toLowerCase()).get(),
      this.getMerchantTransactions(walletAddress),
      this.getMerchantLoans(walletAddress),
    ]);

    if (!merchantDoc.exists) {
      console.warn(`  ⚠️  Merchant ${walletAddress} not found in Firebase`);
      return null;
    }

    const merchantData = {
      ...merchantDoc.data(),
      walletAddress,
      transactions,
      loans,
    };

    // Calculate score
    const score = this.calculator.calculateScore(merchantData);
    const breakdown = this.calculator.getScoreBreakdown(merchantData);

    console.log(`  📊 Score: ${score}`);
    console.log(`     Transactions: ${transactions.length}, Loans: ${loans.length}`);

    // Save to Firebase (independent of blockchain update)
    await this.saveCreditScoreToFirebase(walletAddress, score, breakdown);

    return {
      walletAddress,
      score,
      breakdown,
    };
  }

  /**
   * Update credit score on blockchain for a single merchant
   */
  async updateScoreOnChain(walletAddress, score) {
    console.log(`  📤 Updating on-chain score for ${walletAddress}...`);

    try {
      // Check current on-chain score
      const currentData = await this.contract.getCreditScore(walletAddress);
      const currentScore = Number(currentData.score);

      if (currentScore === score) {
        console.log(`  ✅ Score unchanged (${score}), skipping update`);
        return { skipped: true, txHash: null };
      }

      // Send transaction
      const tx = await this.contract.updateCreditScore(walletAddress, score, {
        gasLimit: 150000,
      });

      console.log(`  ⏳ Transaction sent: ${tx.hash}`);
      console.log(`     Waiting for confirmation...`);

      const receipt = await tx.wait();

      console.log(`  ✅ Transaction confirmed in block ${receipt.blockNumber}`);
      console.log(`     Gas used: ${receipt.gasUsed.toString()}`);

      return {
        skipped: false,
        txHash: tx.hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed.toString(),
      };
    } catch (error) {
      console.error(`  ❌ Error updating score on-chain:`, error.message);
      throw error;
    }
  }

  /**
   * Update credit scores in batch (more gas-efficient)
   */
  async updateScoresBatch(updates) {
    if (updates.length === 0) {
      console.log('No updates to process');
      return;
    }

    console.log(`\n📤 Updating ${updates.length} scores on-chain (batch)...`);

    const addresses = updates.map(u => u.walletAddress);
    const scores = updates.map(u => u.score);

    try {
      // Estimate gas
      const gasEstimate = await this.contract.updateCreditScoresBatch.estimateGas(
        addresses,
        scores
      );

      console.log(`   Estimated gas: ${gasEstimate.toString()}`);

      // Send transaction
      const tx = await this.contract.updateCreditScoresBatch(addresses, scores, {
        gasLimit: gasEstimate * 120n / 100n, // Add 20% buffer
      });

      console.log(`   Transaction sent: ${tx.hash}`);
      console.log(`   Waiting for confirmation...`);

      const receipt = await tx.wait();

      console.log(`✅ Batch update confirmed in block ${receipt.blockNumber}`);
      console.log(`   Gas used: ${receipt.gasUsed.toString()}`);
      console.log(`   Average gas per update: ${receipt.gasUsed / BigInt(updates.length)}`);

      return {
        txHash: tx.hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed.toString(),
        updatesCount: updates.length,
      };
    } catch (error) {
      console.error(`❌ Error in batch update:`, error.message);
      throw error;
    }
  }

  /**
   * Update all merchant credit scores
   */
  async updateAllScores(options = {}) {
    const { batchMode = true, dryRun = false } = options;

    console.log('\n🔄 Starting credit score update job...');
    console.log(`   Mode: ${batchMode ? 'Batch' : 'Individual'}`);
    console.log(`   Dry Run: ${dryRun ? 'Yes' : 'No'}\n`);

    const startTime = Date.now();

    try {
      // Get all active merchants
      console.log('📋 Fetching active merchants...');
      const merchants = await this.getActiveMerchants();
      console.log(`   Found ${merchants.length} active merchants\n`);

      if (merchants.length === 0) {
        console.log('No merchants to update');
        return { success: true, updated: 0 };
      }

      // Calculate scores for all merchants
      console.log('🧮 Calculating credit scores...');
      const scoreUpdates = [];

      for (const merchant of merchants) {
        try {
          const result = await this.calculateMerchantScore(merchant.walletAddress);
          
          if (result && result.score >= 300) {
            scoreUpdates.push(result);
          }
        } catch (error) {
          console.error(`   ❌ Error calculating score for ${merchant.walletAddress}:`, error.message);
        }
      }

      console.log(`\n📊 Calculated ${scoreUpdates.length} scores`);

      if (dryRun) {
        console.log('\n🔍 DRY RUN - Scores would be updated:');
        scoreUpdates.forEach(update => {
          console.log(`   ${update.walletAddress}: ${update.score}`);
        });
        return { success: true, dryRun: true, scores: scoreUpdates };
      }

      // Update on blockchain
      let txResults;
      if (batchMode && scoreUpdates.length > 1) {
        txResults = await this.updateScoresBatch(scoreUpdates);
      } else {
        // Individual updates
        txResults = [];
        for (const update of scoreUpdates) {
          const result = await this.updateScoreOnChain(update.walletAddress, update.score);
          txResults.push(result);
        }
      }

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log(`\n✅ Update job completed in ${duration}s`);
      console.log(`   Updated: ${scoreUpdates.length} merchants`);

      return {
        success: true,
        updated: scoreUpdates.length,
        duration,
        txResults,
      };
    } catch (error) {
      console.error('\n❌ Update job failed:', error);
      throw error;
    }
  }

  /**
   * Get oracle service status
   */
  async getStatus() {
    const balance = await this.provider.getBalance(this.wallet.address);
    const isAuthorized = await this.contract.authorizedOracles(this.wallet.address);

    return {
      initialized: this.initialized,
      oracleAddress: this.wallet.address,
      balance: ethers.formatEther(balance),
      isAuthorized,
      contractAddress: config.creditScoreOracleAddress,
      network: config.rpcUrl,
    };
  }
}

export default OracleService;
