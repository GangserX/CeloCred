# 🏦 CeloCred - Decentralized Credit Scoring for Merchants

[![Celo](https://img.shields.io/badge/Celo-Sepolia_Testnet-35D07F?style=flat&logo=celo)](https://celo-sepolia.blockscout.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Empowering merchants in emerging markets with blockchain-based credit scoring and P2P lending on Celo.

![CeloCred Banner](celocred/assets/images/banner.png)

## 📱 Latest Updates (October 26, 2025)

### Enhanced Merchant Dashboard & QR Scanner
- ✅ **Bidirectional Transaction Tracking**: Dashboard now shows both payments received AND payments sent
- ✅ **Smart QR Code Parsing**: QR scanner automatically verifies merchants on blockchain before payment
- ✅ **Visual Transaction Indicators**: Green ↓ for received payments, Orange ↑ for sent payments
- ✅ **Net Income Tracking**: Dashboard displays totalRevenue, totalSpent, and netIncome
- ✅ **Improved Payment Flow**: Merchants can be both receivers and senders of payments

### Smart Contract Updates
- ✅ **Flexible Payment Recording**: Contracts now support payments to non-merchant addresses (refunds, etc.)
- ✅ **Enhanced Error Handling**: PaymentProcessor uses try-catch for merchant verification
- ✅ **Comprehensive Testing**: 15+ integration tests verify all app features work correctly

### Deployed Contract Addresses (Celo Sepolia Testnet)
```
MerchantRegistry:    0x8d84bB7d706DDDF2406C9584B1a2d5e0A740ebd2
PaymentProcessor:    0xBe5893D9E56d79bdC84C4647184dCB3b772c04D9
LoanEscrow:          0xA692dF938c107d358543eCDa9a91a291ec9A8B8F
CreditScoreOracle:   0x6CE459798353B4Bd0396CA7b4b6893CC26140C41
```

---

## 🌟 Overview

CeloCred is a decentralized credit scoring and lending platform built on **Celo blockchain** that helps merchants build financial reputation through their on-chain transaction history. By leveraging smart contracts and automated oracles, we provide transparent, immutable credit scores that enable access to microloans without traditional banking infrastructure.

### 🎯 Problem We Solve

- **80% of merchants** in emerging markets lack credit history
- Traditional banks require extensive documentation and collateral
- No transparent way to prove financial reliability
- Limited access to working capital for business growth

### 💡 Our Solution

- **On-chain transaction tracking** - Every payment builds credit history
- **Automated credit scoring** - Real-time scores calculated from blockchain data
- **P2P lending marketplace** - Connect merchants with lenders directly
- **NFT collateral support** - Use digital assets to secure larger loans
- **Transparent & immutable** - All records stored on Celo blockchain

---

## ✨ Features

### For Merchants 🏪
- ✅ **Register Business** - One-time blockchain registration with business details
- ✅ **Accept Payments** - Receive CELO & cUSD with automatic credit scoring
- ✅ **Build Credit Score** - 300-850 FICO-like score based on payment history
- ✅ **Request Loans** - Access microloans ($50-$500) with competitive rates
- ✅ **NFT Collateral** - Unlock larger loans using digital assets
- ✅ **Merchant Dashboard** - Track transactions, loans, and credit score

### For Lenders 💰
- ✅ **Browse Loan Requests** - Filter by credit score, amount, and duration
- ✅ **Fund Loans** - Support merchants with transparent risk assessment
- ✅ **Earn Interest** - 5-12% APR based on borrower credit score
- ✅ **Automated Repayments** - Smart contracts handle all transactions

### For Customers 👥
- ✅ **Scan QR to Pay** - Quick payments to merchants
- ✅ **Manual Payments** - Send CELO/cUSD directly to wallet addresses
- ✅ **Transaction History** - View all payment records on-chain

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  (Merchant Dashboard, Payments, Loans, Credit Score)        │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────────┐ ┌─────────┐ ┌──────────────┐
│ WalletConnect│ │Firebase │ │Credit Oracle │
│  (Reown)     │ │Firestore│ │   Backend    │
└──────┬───────┘ └────┬────┘ └──────┬───────┘
       │              │              │
       └──────────────┼──────────────┘
                      │
              ┌───────▼────────┐
              │  Celo Blockchain│
              │ (Sepolia Testnet)│
              └─────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────┐
│ Merchant     │ │ Payment  │ │  Loan    │
│ Registry     │ │Processor │ │ Escrow   │
└──────────────┘ └──────────┘ └──────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.24.5+
- Dart 3.5.4+
- Node.js 18+
- MetaMask or Valora wallet
- Celo Sepolia testnet CELO (get from [faucet](https://faucet.celo.org/celo-sepolia))

### 📱 Run the Mobile App

```bash
# Clone the repository
git clone https://github.com/GangserX/CeloCred.git
cd CeloCred/celocred

# Install dependencies
flutter pub get

# Run on Android/iOS
flutter run
```

### 🔧 Run the Backend Oracle

```bash
# Navigate to backend
cd celocred/backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Test connections
npm test

# Start automatic credit score updates (runs every hour)
npm start
```

---

## 📊 Smart Contracts

All contracts deployed on **Celo Sepolia Testnet** (Chain ID: 11142220):

| Contract | Address | Purpose |
|----------|---------|---------|
| **MerchantRegistry** | [`0xCC54cE...1098`](https://celo-sepolia.blockscout.com/address/0xCC54cE7e70F9680dce54c10Da3AC32b181b71098) | Merchant registration & validation |
| **PaymentProcessor** | [`0xA801662...762c3`](https://celo-sepolia.blockscout.com/address/0xA801662e0fF360680b3C02e3cc9bF422617762c3) | CELO & cUSD payment processing |
| **LoanEscrow** | [`0xEee8DFB...7E8Ab`](https://celo-sepolia.blockscout.com/address/0xEee8DFB32d5385f98674c3089B221E073117E8Ab) | Loan requests, funding & repayments |
| **CreditScoreOracle** | [`0x3aAcA98...aEA1`](https://celo-sepolia.blockscout.com/address/0x3aAcA98e8D7F80B62cE31ac22085C72926EdaEA1) | On-chain credit score storage |

**Network Details:**
- **Network Name**: Celo Sepolia Testnet
- **RPC URL**: https://forno.celo-sepolia.celo-testnet.org
- **Chain ID**: 11142220
- **Currency Symbol**: CELO
- **Block Explorer**: https://celo-sepolia.blockscout.com
- **Faucet**: https://faucet.celo.org/celo-sepolia

### Deploy Your Own Contracts

```bash
cd contracts

# Install dependencies
npm install

# Configure Hardhat
cp .env.example .env
# Add your private key to .env

# Deploy to Celo Sepolia
npx hardhat run scripts/deploy.js --network celosepolia

# Authorize oracle wallet
npx hardhat run scripts/authorizeOracle.js --network celosepolia
```

---

## 🧮 Credit Score Algorithm

Our FICO-like algorithm (300-850 range) considers:

| Factor | Weight | Details |
|--------|--------|---------|
| **Payment History** | 35% | On-time transactions, default rate |
| **Credit Utilization** | 30% | Loan repayment consistency |
| **Account Age** | 15% | Time since merchant registration |
| **Loan Performance** | 10% | Number of successfully repaid loans |
| **Transaction Volume** | 10% | Total transaction count & amounts |

**Score Tiers:**
- 🟢 **750-850**: Excellent (12% max loan limit, 5% APR)
- 🟡 **650-749**: Good (8% max loan limit, 8% APR)
- 🟠 **550-649**: Fair (5% max loan limit, 10% APR)
- 🔴 **300-549**: Building (3% max loan limit, 12% APR)

---

## 📱 App Screenshots

<table>
  <tr>
    
    <td><img src="celocred/assets/images/merchant_dashboard.png" width="250" alt="Merchant Dashboard"/></td>
    <td><img src="celocred/assets/images/loan_marketplace.png" width="250" alt="Loan Marketplace"/></td>
  </tr>
  <tr>
    <td align="center"><b>Home Screen</b></td>
    <td align="center"><b>Merchant Dashboard</b></td>
    <td align="center"><b>Loan Marketplace</b></td>
  </tr>
</table>

---

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Flutter** 3.24.5 - Cross-platform mobile framework
- **Dart** 3.5.4 - Programming language
- **Reown AppKit** - WalletConnect v3 integration
- **web3dart** - Ethereum/Celo blockchain interaction
- **Provider** - State management

### Backend (Oracle Service)
- **Node.js** 18+ - JavaScript runtime
- **Ethers.js** 6.9 - Blockchain interactions
- **Firebase Admin SDK** - Firestore database access
- **node-cron** - Scheduled credit score updates

### Blockchain
- **Celo** - Layer 1 blockchain (low fees, mobile-first)
- **Solidity** 0.8.20 - Smart contract language
- **Hardhat** - Development environment
- **OpenZeppelin** - Secure contract libraries

### Database
- **Firebase Firestore** - NoSQL database for off-chain data
- **Collections**: merchants, transactions, loans, creditScores

---

## 📦 Project Structure

```
CeloCred/
├── celocred/                    # Flutter mobile app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── models/         # Data models (Merchant, Loan, Transaction)
│   │   │   ├── services/       # Blockchain & Firebase services
│   │   │   └── providers/      # State management (WalletProvider)
│   │   ├── features/
│   │   │   ├── home/           # Home screen & navigation
│   │   │   ├── merchant/       # Merchant registration & dashboard
│   │   │   ├── payment/        # QR scanner, manual payment
│   │   │   ├── loan/           # Loan request & repayment
│   │   │   └── marketplace/    # Browse & fund loans
│   │   └── main.dart           # App entry point
│   ├── assets/                 # Images, logos, UI references
│   ├── android/                # Android-specific config
│   └── backend/                # Credit score oracle service
│       ├── oracleService.js    # Main oracle logic
│       ├── creditScoreCalculator.js # Scoring algorithm
│       ├── index.js            # Auto-run service (cron)
│       └── updateScores.js     # Manual update script
│
└── contracts/                   # Smart contracts
    ├── contracts/
    │   ├── MerchantRegistry.sol
    │   ├── PaymentProcessor.sol
    │   ├── LoanEscrow.sol
    │   └── CreditScoreOracle.sol
    ├── scripts/
    │   ├── deploy.js           # Deployment script
    │   └── authorizeOracle.js  # Oracle authorization
    └── hardhat.config.js       # Hardhat configuration
```

---

## 🔐 Security Features

- ✅ **No Private Keys Stored** - WalletConnect handles all signing
- ✅ **OpenZeppelin Contracts** - Audited, battle-tested libraries
- ✅ **ReentrancyGuard** - Protection against reentrancy attacks
- ✅ **Ownable Pattern** - Admin functions restricted to contract owner
- ✅ **NFT Escrow** - Collateral held in smart contract until repayment
- ✅ **Firebase Security Rules** - Access control for off-chain data
- ✅ **Dedicated Oracle Wallet** - Minimal funds, single purpose

---

## 📈 Roadmap

### ✅ Phase 1 (Current - Hackathon MVP)
- [x] Merchant registration on-chain
- [x] CELO & cUSD payment processing
- [x] Automated credit scoring oracle
- [x] Loan request & funding system
- [x] NFT collateral support
- [x] Merchant dashboard with analytics

### 🚧 Phase 2 (Next 3 Months)
- [ ] Mainnet deployment (Celo)
- [ ] KYC integration for merchants
- [ ] Multi-currency support (USDT, USDC)
- [ ] Reputation system for lenders
- [ ] SMS notifications for loan updates
- [ ] Web dashboard for lenders

### 🔮 Phase 3 (6-12 Months)
- [ ] Cross-chain support (Polygon, Optimism)
- [ ] DAO governance for platform parameters
- [ ] Insurance pool for loan defaults
- [ ] Merchant loyalty programs
- [ ] Integration with POS systems
- [ ] Credit score portability across platforms

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See CONTRIBUTING.md for detailed guidelines.

---

## 📄 Documentation

- **[Complete Integration Map](celocred/COMPLETE_INTEGRATION_MAP.md)** - Full architecture & data flows
- **[Backend Setup Guide](celocred/backend/README.md)** - Oracle service configuration
- **[Smart Contract Docs](contracts/README.md)** - Contract deployment & interaction
- **[Deployment Readiness](celocred/DEPLOYMENT_READINESS_REPORT.md)** - Pre-production checklist

---

## 🧪 Testing

### Run Backend Tests
```bash
cd celocred/backend
npm test
```

Expected output:
```
✅ Firebase Connection        PASS
✅ Blockchain Connection      PASS
✅ Oracle Wallet             PASS (9.0 CELO)
✅ Smart Contract            PASS
✅ Oracle Authorization      PASS
```

### Manual Testing Flow
1. Connect wallet via WalletConnect
2. Register as merchant → Check [Blockscout](https://celo-sepolia.blockscout.com)
3. Make test payment → Verify transaction
4. Request loan → Check loan ID on-chain
5. Run `npm run update-scores` → Verify credit score updates

---

## 💰 Gas Costs (Celo Sepolia Testnet)

| Operation | Estimated Gas | Cost (CELO)* |
|-----------|--------------|-------------|
| Register Merchant | ~150,000 | ~0.0001 |
| Process Payment | ~100,000 | ~0.00007 |
| Request Loan | ~200,000 | ~0.00014 |
| Fund Loan | ~120,000 | ~0.00008 |
| Repay Loan | ~110,000 | ~0.00008 |
| Update Credit Score | ~90,000 | ~0.00006 |

*Estimated at 1 Gwei gas price. Testnet is FREE!

---

## 🐛 Known Issues & Limitations

- ⚠️ Currently only supports Celo Sepolia testnet
- ⚠️ Firebase in test mode (open access) - secure before production
- ⚠️ Firebase index required for merchant transactions (create at first query)
- ⚠️ NFT approval flow not yet implemented
- ⚠️ No batch loan funding yet (one at a time)
- ⚠️ Oracle runs locally (needs cloud deployment for 24/7 operation)
- ✅ Type casting issues fixed (num to int/double conversions)

See [Issues](https://github.com/GangserX/CeloCred/issues) for full list.

---

## 🌍 Team

Built with ❤️ by the CeloCred team for [Hackathon Name]

- **Your Name** - [GitHub](https://github.com/yourusername) | [Twitter](https://twitter.com/yourusername)

---

## 📞 Support & Contact

- **GitHub Issues**: [Report a bug](https://github.com/GangserX/CeloCred/issues)
- **Email**: celocred@example.com
- **Discord**: Join our community
- **Documentation**: [Full docs](https://celocred-docs.example.com)

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- **Celo Foundation** - For building a mobile-first blockchain
- **OpenZeppelin** - For secure smart contract libraries
- **Flutter Team** - For an amazing cross-platform framework
- **WalletConnect** - For seamless wallet integration
- **Firebase** - For reliable backend infrastructure

---

## ⭐ Star Us!

If you find this project useful, please give it a star ⭐ to help others discover it!

---

<p align="center">
  <b>Built on Celo • Powered by Smart Contracts • Secured by Blockchain</b>
</p>

<p align="center">
  <a href="https://celo.org">
    <img src="https://img.shields.io/badge/Built%20on-Celo-35D07F?style=for-the-badge&logo=celo" alt="Built on Celo"/>
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Made%20with-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Made with Flutter"/>
  </a>
</p>
