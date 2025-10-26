#!/usr/bin/env node

/**
 * Connection Test Script
 * Tests all backend connections: Firebase, Smart Contracts, and verifies data flow
 */

import { ethers } from 'ethers';
import admin from 'firebase-admin';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   CeloCred Backend Connection Test                       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
`);

const CREDIT_SCORE_ORACLE_ABI = [
  'function updateCreditScore(address _user, uint256 _score) external',
  'function getCreditScore(address _user) external view returns (uint256 score, uint256 lastUpdated, bool exists)',
  'function authorizedOracles(address) external view returns (bool)',
  'function owner() external view returns (address)',
];

async function testFirebaseConnection() {
  console.log('\n1️⃣  Testing Firebase Connection...');
  
  try {
    // Check if service account path exists
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './serviceAccountKey.json';
    const fullPath = resolve(__dirname, serviceAccountPath);
    
    console.log(`   Looking for: ${fullPath}`);
    
    // Initialize Firebase Admin
    if (!admin.apps.length) {
      // Use require for JSON on Windows compatibility
      const { readFileSync } = await import('fs');
      const serviceAccount = JSON.parse(readFileSync(fullPath, 'utf8'));
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    
    const db = admin.firestore();
    
    // Test read
    console.log('   Testing Firestore read...');
    const merchantsSnapshot = await db.collection('merchants').limit(1).get();
    console.log(`   ✅ Firestore connected! Found ${merchantsSnapshot.size} merchant(s)`);
    
    // List all collections
    console.log('   Checking collections...');
    const collections = await db.listCollections();
    console.log('   📁 Available collections:');
    collections.forEach(col => console.log(`      - ${col.id}`));
    
    return true;
  } catch (error) {
    console.error('   ❌ Firebase connection failed:', error.message);
    if (error.message.includes('Cannot find module')) {
      console.error('\n   💡 Solution: Download Firebase service account key:');
      console.error('      1. Go to Firebase Console');
      console.error('      2. Project Settings → Service Accounts');
      console.error('      3. Generate New Private Key');
      console.error('      4. Save as serviceAccountKey.json in /backend folder\n');
    }
    return false;
  }
}

async function testBlockchainConnection() {
  console.log('\n2️⃣  Testing Blockchain Connection...');
  
  try {
    const rpcUrl = process.env.CELO_RPC_URL;
    if (!rpcUrl) {
      console.error('   ❌ CELO_RPC_URL not configured in .env');
      return null;
    }
    
    console.log(`   RPC: ${rpcUrl}`);
    
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    
    // Test connection
    const blockNumber = await provider.getBlockNumber();
    console.log(`   ✅ Connected! Latest block: ${blockNumber}`);
    
    // Test network
    const network = await provider.getNetwork();
    console.log(`   📡 Network: ${network.name} (Chain ID: ${network.chainId})`);
    
    return { provider, blockNumber };
  } catch (error) {
    console.error('   ❌ Blockchain connection failed:', error.message);
    return null;
  }
}

async function testOracleWallet() {
  console.log('\n3️⃣  Testing Oracle Wallet...');
  
  try {
    const privateKey = process.env.ORACLE_PRIVATE_KEY;
    
    if (!privateKey || privateKey === 'your_private_key_here') {
      console.error('   ❌ Oracle private key not configured');
      console.error('\n   💡 Solution: Generate a new wallet:');
      console.error('      node -e "const {Wallet} = require(\'ethers\'); const w = Wallet.createRandom(); console.log(\'Address:\', w.address); console.log(\'Private Key:\', w.privateKey)"');
      console.error('      Then add to .env file\n');
      return null;
    }
    
    const rpcUrl = process.env.CELO_RPC_URL;
    if (!rpcUrl) {
      console.error('   ❌ CELO_RPC_URL not configured in .env');
      return null;
    }
    
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);
    
    console.log(`   Address: ${wallet.address}`);
    
    // Check balance
    const balance = await provider.getBalance(wallet.address);
    const balanceInCelo = ethers.formatEther(balance);
    console.log(`   Balance: ${balanceInCelo} CELO`);
    
    if (parseFloat(balanceInCelo) < 0.01) {
      console.warn('   ⚠️  Low balance! Fund wallet at: https://faucet.celo.org/alfajores');
    } else {
      console.log('   ✅ Wallet funded');
    }
    
    return wallet;
  } catch (error) {
    console.error('   ❌ Wallet test failed:', error.message);
    return null;
  }
}

async function testSmartContract() {
  console.log('\n4️⃣  Testing Smart Contract Connection...');
  
  try {
    const contractAddress = process.env.CREDIT_SCORE_ORACLE_ADDRESS;
    
    if (!contractAddress || contractAddress === '0x0000000000000000000000000000000000000000') {
      console.error('   ❌ Contract address not configured');
      return null;
    }
    
    console.log(`   Contract: ${contractAddress}`);
    
    const rpcUrl = process.env.CELO_RPC_URL;
    if (!rpcUrl) {
      console.error('   ❌ CELO_RPC_URL not configured in .env');
      return null;
    }
    
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const contract = new ethers.Contract(contractAddress, CREDIT_SCORE_ORACLE_ABI, provider);
    
    // Test contract is deployed
    const code = await provider.getCode(contractAddress);
    if (code === '0x') {
      console.error('   ❌ No contract deployed at this address');
      return null;
    }
    
    console.log('   ✅ Contract found at address');
    
    // Test reading from contract
    const owner = await contract.owner();
    console.log(`   👤 Contract owner: ${owner}`);
    
    return contract;
  } catch (error) {
    console.error('   ❌ Contract test failed:', error.message);
    return null;
  }
}

async function testOracleAuthorization(contract, wallet) {
  console.log('\n5️⃣  Testing Oracle Authorization...');
  
  try {
    const isAuthorized = await contract.authorizedOracles(wallet.address);
    
    if (isAuthorized) {
      console.log('   ✅ Oracle wallet is AUTHORIZED');
      return true;
    } else {
      console.error('   ❌ Oracle wallet is NOT authorized');
      console.error('\n   💡 Solution: Authorize wallet with contract owner:');
      console.error('      1. Connect to contract with owner wallet');
      console.error(`      2. Call: setOracle("${wallet.address}", true)`);
      console.error('      3. Re-run this test\n');
      return false;
    }
  } catch (error) {
    console.error('   ❌ Authorization check failed:', error.message);
    return false;
  }
}

async function testEndToEndFlow() {
  console.log('\n6️⃣  Testing End-to-End Data Flow...');
  
  try {
    const db = admin.firestore();
    
    // Get a sample merchant
    console.log('   Fetching sample merchant from Firebase...');
    const merchantsSnapshot = await db
      .collection('merchants')
      .where('isActive', '==', true)
      .limit(1)
      .get();
    
    if (merchantsSnapshot.empty) {
      console.warn('   ⚠️  No active merchants found in Firebase');
      console.log('   💡 Register a merchant in the app first');
      return false;
    }
    
    const merchantDoc = merchantsSnapshot.docs[0];
    const merchantData = merchantDoc.data();
    const walletAddress = merchantDoc.id;
    
    console.log(`   ✅ Found merchant: ${merchantData.businessName}`);
    console.log(`      Wallet: ${walletAddress}`);
    
    // Get transactions
    console.log('   Fetching transactions...');
    const txSnapshot = await db
      .collection('transactions')
      .where('merchantAddress', '==', walletAddress.toLowerCase())
      .get();
    
    console.log(`   ✅ Found ${txSnapshot.size} transaction(s)`);
    
    // Check blockchain score
    console.log('   Checking on-chain credit score...');
    const contractAddress = process.env.CREDIT_SCORE_ORACLE_ADDRESS;
    const rpcUrl = process.env.CELO_RPC_URL;
    if (!rpcUrl) {
      console.error('   ❌ CELO_RPC_URL not configured in .env');
      return false;
    }
    
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const contract = new ethers.Contract(contractAddress, CREDIT_SCORE_ORACLE_ABI, provider);
    
    const scoreData = await contract.getCreditScore(walletAddress);
    const score = Number(scoreData.score);
    const exists = scoreData.exists;
    
    console.log(`   📊 On-chain score: ${score} (${exists ? 'exists' : 'not set'})`);
    
    if (!exists || score === 0) {
      console.log('   💡 Score needs to be updated. Run: npm run update-scores');
    }
    
    console.log('\n   ✅ End-to-end flow verified!');
    return true;
  } catch (error) {
    console.error('   ❌ End-to-end test failed:', error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('Starting connection tests...\n');
  
  let allPassed = true;
  
  // Test 1: Firebase
  const firebaseOk = await testFirebaseConnection();
  if (!firebaseOk) allPassed = false;
  
  // Test 2: Blockchain
  const blockchainResult = await testBlockchainConnection();
  if (!blockchainResult) allPassed = false;
  
  // Test 3: Oracle Wallet
  const wallet = await testOracleWallet();
  if (!wallet) allPassed = false;
  
  // Test 4: Smart Contract
  const contract = await testSmartContract();
  if (!contract) allPassed = false;
  
  // Test 5: Oracle Authorization (only if wallet and contract are ok)
  let authorized = false;
  if (wallet && contract) {
    authorized = await testOracleAuthorization(contract, wallet);
    if (!authorized) allPassed = false;
  }
  
  // Test 6: End-to-end (only if previous tests passed)
  if (firebaseOk && blockchainResult && wallet && contract) {
    await testEndToEndFlow();
  }
  
  // Summary
  console.log('\n' + '═'.repeat(60));
  console.log('📊 Test Summary:');
  console.log('═'.repeat(60));
  console.log(`Firebase Connection:      ${firebaseOk ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Blockchain Connection:    ${blockchainResult ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Oracle Wallet:            ${wallet ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Smart Contract:           ${contract ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Oracle Authorization:     ${authorized ? '✅ PASS' : '❌ FAIL'}`);
  console.log('═'.repeat(60));
  
  if (allPassed && authorized) {
    console.log('\n🎉 All tests passed! Backend is ready to use.');
    console.log('   Run: npm start (to start automatic updates)');
    console.log('   Or:  npm run update-scores (for manual update)\n');
  } else {
    console.log('\n⚠️  Some tests failed. Fix issues above and re-run: npm test\n');
  }
  
  process.exit(allPassed && authorized ? 0 : 1);
}

// Run tests
runAllTests();
