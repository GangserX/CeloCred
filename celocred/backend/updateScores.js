#!/usr/bin/env node

/**
 * Manual Credit Score Update Script
 * 
 * Run this script manually to update credit scores without starting the service:
 * npm run update-scores
 */

import { config, validateConfig } from './config.js';
import { OracleService } from './oracleService.js';

console.log('🔄 Manual Credit Score Update\n');

async function updateScores() {
  try {
    // Validate configuration
    validateConfig();

    // Initialize oracle
    const oracle = new OracleService();
    await oracle.initialize();

    // Check if we should do a dry run
    const dryRun = process.argv.includes('--dry-run');
    const batchMode = !process.argv.includes('--individual');

    if (dryRun) {
      console.log('🔍 Running in DRY RUN mode (no blockchain updates)\n');
    }

    // Run update
    const result = await oracle.updateAllScores({ 
      batchMode,
      dryRun,
    });

    if (result.success) {
      console.log('\n✅ Update completed successfully!');
      process.exit(0);
    } else {
      console.error('\n❌ Update failed');
      process.exit(1);
    }
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  }
}

updateScores();
