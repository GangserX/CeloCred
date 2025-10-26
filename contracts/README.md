# CeloCred Smart Contracts

Smart contracts for the CeloCred decentralized credit platform on Celo blockchain.

## 📋 Contracts

1. **MerchantRegistry** - Register and manage merchant profiles
2. **PaymentProcessor** - Process CELO and cUSD payments
3. **LoanEscrow** - Manage loans with optional NFT collateral
4. **CreditScoreOracle** - Store credit scores on-chain

## 🚀 Deployment Guide

### Prerequisites

1. **Node.js & npm** installed
2. **Celo wallet** with testnet CELO
3. **Get testnet CELO**: https://faucet.celo.org

### Step 1: Install Dependencies

```bash
cd contracts
npm install
```

### Step 2: Setup Environment

1. Copy `.env.example` to `.env`:
```bash
copy .env.example .env
```

2. Add your private key to `.env`:
```
PRIVATE_KEY=your_private_key_here_without_0x
```

**⚠️ IMPORTANT**: 
- NEVER commit your `.env` file
- Use a testnet wallet only
- Get testnet CELO from: https://faucet.celo.org

### Step 3: Compile Contracts

```bash
npm run compile
```

### Step 4: Deploy to Alfajores

```bash
npm run deploy
```

This will:
- Deploy all 4 contracts to Celo Alfajores testnet
- Link contracts together
- Show you the deployed contract addresses

### Step 5: Update Flutter App

Copy the contract addresses from the deployment output and paste them into:

**File**: `celocred/lib/core/constants/celo_config.dart`

Replace these lines:
```dart
static const String merchantRegistryAddress = 'YOUR_NEW_ADDRESS';
static const String paymentProcessorAddress = 'YOUR_NEW_ADDRESS';
static const String loanEscrowAddress = 'YOUR_NEW_ADDRESS';
static const String creditScoreOracleAddress = 'YOUR_NEW_ADDRESS';
```

### Step 6: Rebuild Flutter App

```bash
cd ../celocred
flutter run -d YOUR_DEVICE
```

## 🔄 Redeploying

If you need to update contracts:

1. Modify the `.sol` files
2. Run `npm run compile`
3. Run `npm run deploy`
4. Update the new addresses in Flutter app
5. Rebuild the app

## 🌐 Network Info

**Alfajores Testnet**:
- Chain ID: 44787
- RPC: https://alfajores-forno.celo-testnet.org
- Explorer: https://alfajores.celoscan.io
- Faucet: https://faucet.celo.org

**cUSD Token**: `0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1`

## 📝 Contract Functions

### MerchantRegistry
- `registerMerchant()` - Register as a merchant
- `updateMerchant()` - Update merchant info
- `getMerchant()` - Get merchant details
- `isMerchant()` - Check if address is merchant

### PaymentProcessor
- `payWithCELO()` - Pay merchant in CELO
- `payWithCUSD()` - Pay merchant in cUSD
- `getPayment()` - Get payment details
- `getCustomerPayments()` - Get customer's payment history
- `getMerchantPayments()` - Get merchant's payment history

### LoanEscrow
- `requestLoan()` - Request loan without collateral
- `requestLoanWithCollateral()` - Request loan with NFT collateral
- `fundLoan()` - Fund a pending loan
- `repayLoan()` - Repay an active loan
- `claimCollateral()` - Claim collateral on defaulted loan
- `getPendingLoans()` - Get all available loans

### CreditScoreOracle
- `updateCreditScore()` - Update user's credit score (owner only)
- `getCreditScore()` - Get credit score for address
- `hasScore()` - Check if user has score

## 🔐 Security Notes

- Contracts use OpenZeppelin libraries
- ReentrancyGuard on payment functions
- Ownable pattern for admin functions
- Test thoroughly before mainnet deployment

## 📞 Support

For issues or questions, check:
- Celo Docs: https://docs.celo.org
- Hardhat Docs: https://hardhat.org/docs

## ⚠️ Disclaimer

These contracts are for hackathon/testing purposes. Audit before mainnet use.
