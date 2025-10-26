# CeloCred# CeloCred - Mobile Payment on Celo Blockchain



A Flutter mobile payment application for the Celo blockchain.A Flutter-based mobile payment application built on the Celo blockchain, featuring secure wallet management, token transfers, and QR code scanning.



## Getting Started## Features



This project is a starting point for building a Celo-based mobile payment app.✅ **Wallet Management**

- Create new wallets with secure key generation

### Prerequisites- Import existing wallets using private keys

- Secure storage of credentials using `flutter_secure_storage`

- Flutter SDK (3.9.2 or higher)- View wallet balance across multiple tokens (CELO, cUSD, cEUR)

- Dart SDK

- Android Studio (for Android development)✅ **Token Support**

- Xcode (for iOS development, macOS only)- CELO (native token)

- cUSD (Celo Dollar)

### Dependencies- cEUR (Celo Euro)



This project includes the following Celo and blockchain-related packages:✅ **Payment Features**

- Send payments with any supported token

- `web3dart` - Ethereum and Celo blockchain interaction- Input validation and balance checks

- `walletconnect_flutter_v2` - WalletConnect protocol support- Transaction confirmation and tracking

- `flutter_secure_storage` - Secure credential storage- Copy wallet address to clipboard

- `mobile_scanner` - QR code scanning

- `qr_flutter` - QR code generation✅ **QR Code Scanner**

- `http` - HTTP requests- Scan wallet addresses

- `url_launcher` - URL and deep link handling- Scan WalletConnect URIs

- Scan payment URIs (celo:// and ethereum://)

### Installation- Flashlight and camera flip support



```bash## Project Structure

flutter pub get

``````

lib/

### Run the App├── main.dart                          # App entry point

├── core/

```bash│   ├── constants/

flutter run│   │   └── celo_config.dart          # Blockchain configuration

```│   ├── models/

│   │   ├── wallet_model.dart         # Wallet data model

## Resources│   │   └── transaction_model.dart    # Transaction data model

│   └── services/

- [Celo Documentation](https://docs.celo.org)│       ├── storage_service.dart      # Secure storage service

- [Flutter Documentation](https://flutter.dev)│       └── web3_service.dart         # Web3/blockchain service

- [Web3dart Package](https://pub.dev/packages/web3dart)└── features/

    ├── wallet/
    │   └── wallet_screen.dart        # Main wallet screen
    ├── payment/
    │   └── payment_screen.dart       # Payment/send screen
    └── scanner/
        └── qr_scanner_screen.dart    # QR code scanner
```

## Setup Instructions

### 1. Enable Developer Mode (Windows)
```powershell
start ms-settings:developers
```
Toggle **Developer Mode** to **ON**

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Network
Edit `lib/core/constants/celo_config.dart`:
```dart
// Set to false for mainnet, true for testnet
static const bool useTestnet = true;
```

### 4. Run the App
```bash
flutter run
```

## Getting Testnet Tokens

Visit the [Celo Faucet](https://faucet.celo.org) to get free testnet tokens for development.

## Resources

- [Celo Documentation](https://docs.celo.org)
- [Web3dart Documentation](https://pub.dev/packages/web3dart)
- [Flutter Documentation](https://flutter.dev/docs)

Built with ❤️ on Celo
