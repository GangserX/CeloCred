#!/usr/bin/env node

/**
 * CeloCred Credit Score Oracle Service
 * 
 * This service automatically updates credit scores on the blockchain
 * by calculating them from Firebase transaction and loan data.
 */

import cron from 'node-cron';
import { config, validateConfig } from './config.js';
import { OracleService } from './oracleService.js';

console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   CeloCred Credit Score Oracle Service                   ║
║   Version 1.0.0                                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
`);

async function main() {
  try {
    // Validate configuration
    console.log('🔧 Validating configuration...');
    validateConfig();
    console.log('✅ Configuration valid\n');

    // Initialize oracle service
    const oracle = new OracleService();
    await oracle.initialize();

    // Show status
    const status = await oracle.getStatus();
    console.log('📊 Oracle Status:');
    console.log(`   Address: ${status.oracleAddress}`);
    console.log(`   Balance: ${status.balance} CELO`);
    console.log(`   Authorized: ${status.isAuthorized ? '✅ Yes' : '❌ No'}`);
    console.log(`   Contract: ${status.contractAddress}`);
    console.log(`   Network: ${status.network}\n`);

    if (!status.isAuthorized) {
      console.error('❌ ERROR: Oracle wallet is not authorized!');
      console.error('   Please authorize this wallet in the CreditScoreOracle contract.');
      console.error(`   Run: setOracle("${status.oracleAddress}", true)`);
      process.exit(1);
    }

    if (parseFloat(status.balance) < 0.1) {
      console.warn('⚠️  WARNING: Low balance! Please fund wallet with CELO.');
      console.warn(`   Send CELO to: ${status.oracleAddress}`);
      console.warn('   Faucet: https://faucet.celo.org/alfajores\n');
    }

    // Run initial update
    if (config.autoUpdateEnabled) {
      console.log('🚀 Running initial credit score update...\n');
      await oracle.updateAllScores({ batchMode: true });
    }

    // Schedule automatic updates
    if (config.autoUpdateEnabled) {
      console.log(`\n⏰ Scheduling automatic updates: ${config.updateCronSchedule}`);
      console.log('   (Press Ctrl+C to stop)\n');

      cron.schedule(config.updateCronSchedule, async () => {
        console.log(`\n[${ new Date().toISOString() }] Running scheduled update...`);
        try {
          await oracle.updateAllScores({ batchMode: true });
        } catch (error) {
          console.error('❌ Scheduled update failed:', error);
        }
      });

      // Keep process running
      console.log('✅ Oracle service is running...\n');
    } else {
      console.log('\n⚠️  Auto-update is disabled (set AUTO_UPDATE_ENABLED=true to enable)');
      console.log('   Service will exit after initial update.\n');
      process.exit(0);
    }
  } catch (error) {
    console.error('\n❌ Fatal error:', error.message);
    if (config.logLevel === 'debug') {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n👋 Shutting down oracle service...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n👋 Shutting down oracle service...');
  process.exit(0);
});

// Start the service
main();
