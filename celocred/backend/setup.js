#!/usr/bin/env node

/**
 * Setup Helper Script
 * Helps configure the backend service step-by-step
 */

import { existsSync, writeFileSync, readFileSync } from 'fs';
import { Wallet } from 'ethers';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   CeloCred Backend Setup Helper                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
`);

async function checkEnvFile() {
  const envPath = resolve(__dirname, '.env');
  const envExamplePath = resolve(__dirname, '.env.example');
  
  if (!existsSync(envPath)) {
    console.log('📝 Creating .env file from example...');
    
    if (!existsSync(envExamplePath)) {
      console.error('❌ .env.example not found!');
      return false;
    }
    
    const envContent = readFileSync(envExamplePath, 'utf-8');
    writeFileSync(envPath, envContent);
    console.log('✅ Created .env file\n');
  } else {
    console.log('✅ .env file exists\n');
  }
  
  return true;
}

async function generateOracleWallet() {
  console.log('🔑 Oracle Wallet Generation\n');
  
  const envPath = resolve(__dirname, '.env');
  let envContent = readFileSync(envPath, 'utf-8');
  
  // Check if already configured
  if (!envContent.includes('ORACLE_PRIVATE_KEY=your_private_key_here')) {
    console.log('✅ Oracle wallet already configured\n');
    return true;
  }
  
  console.log('Generating new oracle wallet...');
  const wallet = Wallet.createRandom();
  
  console.log('\n📋 New Oracle Wallet Details:');
  console.log('═'.repeat(60));
  console.log(`Address:     ${wallet.address}`);
  console.log(`Private Key: ${wallet.privateKey}`);
  console.log('═'.repeat(60));
  
  console.log('\n⚠️  IMPORTANT: Keep this private key SECRET!');
  console.log('   Do NOT share it or commit it to git.\n');
  
  console.log('💰 Fund this wallet:');
  console.log('   1. Copy the address above');
  console.log('   2. Visit: https://faucet.celo.org/alfajores');
  console.log('   3. Request 5 CELO (free testnet tokens)\n');
  
  // Update .env file
  envContent = envContent.replace(
    'ORACLE_PRIVATE_KEY=your_private_key_here',
    `ORACLE_PRIVATE_KEY=${wallet.privateKey}`
  );
  
  writeFileSync(envPath, envContent);
  console.log('✅ Updated .env with oracle private key\n');
  
  return wallet;
}

async function checkFirebaseConfig() {
  console.log('🔥 Firebase Configuration\n');
  
  const serviceAccountPath = resolve(__dirname, 'serviceAccountKey.json');
  
  if (!existsSync(serviceAccountPath)) {
    console.log('❌ Firebase service account key not found\n');
    console.log('📋 Follow these steps:');
    console.log('   1. Go to: https://console.firebase.google.com/');
    console.log('   2. Select your project');
    console.log('   3. Go to: Project Settings → Service Accounts');
    console.log('   4. Click: "Generate New Private Key"');
    console.log('   5. Save the downloaded file as: serviceAccountKey.json');
    console.log(`   6. Move it to: ${__dirname}\n`);
    return false;
  }
  
  console.log('✅ Firebase service account key found\n');
  
  // Validate it's a valid JSON
  try {
    const content = JSON.parse(readFileSync(serviceAccountPath, 'utf-8'));
    if (!content.project_id || !content.private_key) {
      console.error('❌ Invalid service account key format\n');
      return false;
    }
    console.log(`   Project ID: ${content.project_id}`);
    console.log('   ✅ Valid service account key\n');
    return true;
  } catch (error) {
    console.error('❌ Error reading service account key:', error.message);
    return false;
  }
}

async function checkContractAddresses() {
  console.log('📄 Smart Contract Configuration\n');
  
  const envPath = resolve(__dirname, '.env');
  const envContent = readFileSync(envPath, 'utf-8');
  
  // Extract contract address
  const match = envContent.match(/CREDIT_SCORE_ORACLE_ADDRESS=(.+)/);
  if (!match) {
    console.error('❌ CREDIT_SCORE_ORACLE_ADDRESS not found in .env\n');
    return false;
  }
  
  const address = match[1].trim();
  
  if (address === '0x0000000000000000000000000000000000000000') {
    console.error('❌ Contract address not configured\n');
    console.log('📋 Update .env with deployed contract address:');
    console.log('   CREDIT_SCORE_ORACLE_ADDRESS=0x62468b565962f7713f939590B819AFDB5177bD08\n');
    return false;
  }
  
  console.log(`✅ Contract address configured: ${address}\n`);
  return true;
}

async function showNextSteps(wallet) {
  console.log('\n' + '═'.repeat(60));
  console.log('📋 Next Steps:');
  console.log('═'.repeat(60));
  
  console.log('\n1️⃣  Fund Oracle Wallet (if not already done):');
  if (wallet && wallet.address) {
    console.log(`   Address: ${wallet.address}`);
  }
  console.log('   Visit: https://faucet.celo.org/alfajores');
  console.log('   Request: 5 CELO\n');
  
  console.log('2️⃣  Authorize Oracle Wallet:');
  console.log('   cd ../contracts');
  console.log('   npx hardhat console --network alfajores');
  console.log('   ');
  console.log('   # In console:');
  console.log('   const oracle = await ethers.getContractAt("CreditScoreOracle", "0x62468b565962f7713f939590B819AFDB5177bD08")');
  if (wallet && wallet.address) {
    console.log(`   await oracle.setOracle("${wallet.address}", true)`);
  } else {
    console.log('   await oracle.setOracle("YOUR_ORACLE_ADDRESS", true)');
  }
  console.log('\n3️⃣  Test Connections:');
  console.log('   npm test\n');
  
  console.log('4️⃣  Run Manual Update:');
  console.log('   npm run update-scores -- --dry-run  (safe test)');
  console.log('   npm run update-scores                (real update)\n');
  
  console.log('5️⃣  Start Automatic Service:');
  console.log('   npm start\n');
  
  console.log('═'.repeat(60) + '\n');
}

async function runSetup() {
  console.log('Starting setup...\n');
  
  // Step 1: Check/create .env
  const envOk = await checkEnvFile();
  if (!envOk) {
    console.error('Setup failed at .env creation');
    process.exit(1);
  }
  
  // Step 2: Generate oracle wallet
  const wallet = await generateOracleWallet();
  
  // Step 3: Check Firebase config
  const firebaseOk = await checkFirebaseConfig();
  
  // Step 4: Check contract addresses
  const contractOk = await checkContractAddresses();
  
  // Summary
  console.log('═'.repeat(60));
  console.log('Setup Status:');
  console.log('═'.repeat(60));
  console.log(`Environment file:         ✅ OK`);
  console.log(`Oracle wallet:            ${wallet ? '✅ OK' : '⚠️  Check .env'}`);
  console.log(`Firebase config:          ${firebaseOk ? '✅ OK' : '❌ MISSING'}`);
  console.log(`Contract address:         ${contractOk ? '✅ OK' : '❌ MISSING'}`);
  console.log('═'.repeat(60));
  
  if (!firebaseOk || !contractOk) {
    console.log('\n⚠️  Setup incomplete. Fix issues above and re-run: npm run setup\n');
    process.exit(1);
  }
  
  // Show next steps
  await showNextSteps(wallet);
  
  console.log('✅ Setup complete! Follow the steps above to finish configuration.\n');
}

runSetup();
