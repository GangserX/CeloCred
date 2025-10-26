import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
dotenv.config();

export const config = {
  // Celo Network
  rpcUrl: process.env.CELO_RPC_URL || 'https://alfajores-forno.celo-testnet.org',
  chainId: parseInt(process.env.CHAIN_ID || '44787'),
  
  // Smart Contracts
  creditScoreOracleAddress: process.env.CREDIT_SCORE_ORACLE_ADDRESS,
  
  // Oracle Wallet
  oraclePrivateKey: process.env.ORACLE_PRIVATE_KEY,
  
  // Firebase
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH 
    ? resolve(__dirname, process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : null,
  
  // Update Schedule
  updateCronSchedule: process.env.UPDATE_CRON_SCHEDULE || '0 * * * *',
  
  // Score Calculation
  minTransactionsForScore: parseInt(process.env.MIN_TRANSACTIONS_FOR_SCORE || '3'),
  
  // Feature Flags
  autoUpdateEnabled: process.env.AUTO_UPDATE_ENABLED === 'true',
  
  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
};

// Validation
export function validateConfig() {
  const errors = [];
  
  if (!config.creditScoreOracleAddress) {
    errors.push('CREDIT_SCORE_ORACLE_ADDRESS is required');
  }
  
  if (!config.oraclePrivateKey || config.oraclePrivateKey === 'your_private_key_here') {
    errors.push('ORACLE_PRIVATE_KEY is required (generate a new wallet)');
  }
  
  if (!config.firebaseServiceAccountPath) {
    errors.push('FIREBASE_SERVICE_ACCOUNT_PATH is required');
  }
  
  if (errors.length > 0) {
    throw new Error(`Configuration errors:\n${errors.join('\n')}`);
  }
  
  return true;
}
