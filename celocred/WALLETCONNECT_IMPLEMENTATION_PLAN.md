# 🔐 WalletConnect Security Fix - Implementation Plan

## 🚨 Critical Security Issue Identified

**Problem:** The current app stores and uses private keys directly, which means:
- ❌ Anyone can import ANY wallet's private key and steal funds
- ❌ No user approval for transactions
- ❌ Private keys stored in app (even if "secure" storage)
- ❌ This is like giving away your bank password!

## ✅ Proper Solution: Reown AppKit (WalletConnect)

**How MetaMask/Valora Actually Work:**
- ✅ App NEVER sees your private key
- ✅ App sends transaction REQUEST to wallet
- ✅ User APPROVES/REJECTS in their wallet app
- ✅ Wallet signs and returns transaction
- ✅ App broadcasts signed transaction

---

## 📦 Package Installed

```yaml
reown_appkit: ^1.7.0  # ✅ Added to pubspec.yaml
```

This is the official WalletConnect v2 package for Flutter (formerly `web3modal`).

---

## 🎯 Implementation Steps

### **Step 1: Get WalletConnect Project ID**

1. Go to https://cloud.reown.com/
2. Sign up/login
3. Create new project "CeloCred"
4. Copy Project ID
5. Add to `lib/core/constants/celo_config.dart`:

```dart
static const String walletConnectProjectId = 'YOUR_PROJECT_ID_HERE';
```

---

### **Step 2: Configure Deep Linking (CRITICAL)**

#### **iOS Setup** (`ios/Runner/Info.plist`):

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>celo</string>          <!-- Valora -->
  <string>metamask</string>      <!-- MetaMask -->
  <string>trust</string>         <!-- Trust Wallet -->
  <string>rainbow</string>       <!-- Rainbow -->
</array>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.celocred</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>celocred</string>  <!-- Your app's scheme -->
    </array>
  </dict>
</array>
```

#### **Android Setup** (`android/app/src/main/AndroidManifest.xml`):

Add inside `<manifest>`:
```xml
<queries>
  <package android:name="co.clabs.valora" />
  <package android:name="io.metamask" />
</queries>
```

Add inside `<activity>`:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="celocred" />
</intent-filter>
```

---

### **Step 3: Create AppKit Service**

Create `lib/core/services/appkit_service.dart`:

```dart
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';
import '../constants/celo_config.dart';

class AppKitService {
  static AppKitService? _instance;
  late ReownAppKitModal _appKitModal;
  
  static AppKitService get instance {
    _instance ??= AppKitService._();
    return _instance!;
  }
  
  AppKitService._() {
    _initialize();
  }
  
  void _initialize() {
    _appKitModal = ReownAppKitModal(
      context: context, // Pass from widget
      projectId: CeloConfig.walletConnectProjectId,
      metadata: const PairingMetadata(
        name: 'CeloCred',
        description: 'Decentralized Credit Platform on Celo',
        url: 'https://celocred.app',
        icons: ['https://celocred.app/icon.png'],
        redirect: Redirect(
          native: 'celocred://',
          universal: 'https://celocred.app',
        ),
      ),
      requiredNamespaces: {
        'eip155': RequiredNamespace(
          chains: ['eip155:44787'], // Celo Alfajores
          methods: [
            'eth_sendTransaction',
            'eth_signTransaction',
            'eth_sign',
            'personal_sign',
            'eth_signTypedData',
          ],
          events: ['chainChanged', 'accountsChanged'],
        ),
      },
    );
  }
  
  // Connect wallet
  Future<String?> connect() async {
    await _appKitModal.openModalView();
    // Wait for connection
    if (_appKitModal.session != null) {
      return _appKitModal.session!.address;
    }
    return null;
  }
  
  // Get connected address
  String? get connectedAddress => _appKitModal.session?.address;
  
  // Check if connected
  bool get isConnected => _appKitModal.session != null;
  
  // Disconnect
  Future<void> disconnect() async {
    await _appKitModal.disconnect();
  }
  
  // Sign and send transaction
  Future<String> sendTransaction({
    required String to,
    required BigInt value,
    String? data,
  }) async {
    if (!isConnected) throw Exception('Wallet not connected');
    
    final txHash = await _appKitModal.request(
      topic: _appKitModal.session!.topic,
      chainId: 'eip155:44787',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {
            'from': connectedAddress,
            'to': to,
            'value': '0x${value.toRadixString(16)}',
            'data': data ?? '0x',
          }
        ],
      ),
    );
    
    return txHash;
  }
}
```

---

### **Step 4: Rewrite ContractService (NO MORE PRIVATE KEYS!)**

Update `lib/core/services/contract_service.dart`:

```dart
// OLD (INSECURE):
Future<String> registerMerchant({
  required String privateKeyHex,  // ❌ REMOVE THIS
  required String businessName,
  // ...
}) async {
  final credentials = EthPrivateKey(hexToBytes(privateKeyHex));  // ❌ BAD
  // ...
}

// NEW (SECURE):
Future<String> registerMerchant({
  required String businessName,
  required String category,
  required String location,
}) async {
  if (!AppKitService.instance.isConnected) {
    throw Exception('Please connect your wallet first');
  }
  
  final function = _merchantRegistry.function('registerMerchant');
  final data = function.encodeCall([businessName, category, location]);
  
  // Send to wallet for approval
  final txHash = await AppKitService.instance.sendTransaction(
    to: CeloConfig.merchantRegistryAddress,
    value: BigInt.zero,
    data: bytesToHex(data, include0x: true),
  );
  
  print('✅ Transaction sent! User approved in wallet: $txHash');
  return txHash;
}
```

Apply same changes to:
- `payWithCELO()` - Remove privateKeyHex, use AppKitService
- `payWithCUSD()` - Remove privateKeyHex, use AppKitService for 2 txs (approve + transfer)
- `requestLoan()` - Remove privateKeyHex, use AppKitService
- All other transaction methods

---

### **Step 5: Update Wallet Setup Screen**

Replace `lib/features/wallet/wallet_setup_screen.dart`:

```dart
// OLD:
ElevatedButton(
  onPressed: _createNewWallet,  // ❌ Generated private key
  child: const Text('Create New Wallet'),
)

// NEW:
ElevatedButton(
  onPressed: _connectWallet,  // ✅ Opens WalletConnect modal
  child: const Text('Connect Wallet'),
)

Future<void> _connectWallet() async {
  final address = await AppKitService.instance.connect();
  
  if (address != null) {
    // Save only the ADDRESS (never private key!)
    await _storage.saveWalletAddress(address);
    await _storage.setLoggedIn(true);
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Connected: ${address.substring(0, 10)}...'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate
    _navigateToNextScreen(address);
  }
}
```

**Remove these INSECURE functions:**
- `_createNewWallet()` ❌
- `_importWallet()` ❌
- `_privateKeyController` ❌
- All private key input fields ❌

---

### **Step 6: Update Payment Screens with Approval Flow**

Update `lib/features/payment/payment_confirmation_screen.dart`:

```dart
Future<void> _processPayment() async {
  // ... validation ...
  
  setState(() {
    _isProcessing = true;
  });

  try {
    // Show message that wallet will open
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text('📱 Opening Valora for approval...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
    
    // 🚀 REAL BLOCKCHAIN TRANSACTION (with user approval)
    String txHash;
    if (_selectedToken == 'CELO') {
      // Wallet will ask: "Send 0.1 CELO to 0x742d35...?"
      txHash = await _contractService.payWithCELO(
        merchantAddress: widget.merchantAddress,
        amount: amount,
        note: 'Payment to ${widget.merchantName}',
      );
    } else if (_selectedToken == 'cUSD') {
      // Wallet will ask TWICE:
      // 1. "Approve PaymentProcessor to spend cUSD?"
      // 2. "Send 10 cUSD to merchant?"
      txHash = await _contractService.payWithCUSD(
        merchantAddress: widget.merchantAddress,
        amount: amount,
        note: 'Payment to ${widget.merchantName}',
      );
    }
    
    print('✅ User approved! TxHash: $txHash');
    // ... success screen ...
    
  } on UserRejected catch (e) {
    // User clicked "Reject" in wallet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Transaction rejected by user'),
        backgroundColor: Colors.orange,
      ),
    );
  } catch (e) {
    // Other errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isProcessing = false;
    });
  }
}
```

---

### **Step 7: Clean Up Storage Service**

Update `lib/core/services/storage_service.dart`:

```dart
// ❌ DELETE THESE FUNCTIONS:
// Future<void> savePrivateKey(String privateKey) async { ... }
// Future<String?> getPrivateKey() async { ... }
// Future<void> saveMnemonic(String mnemonic) async { ... }
// Future<String?> getMnemonic() async { ... }

// ✅ KEEP ONLY:
Future<void> saveWalletAddress(String address) async {
  await _storage.write(key: _keyWalletAddress, value: address);
}

Future<String?> getWalletAddress() async {
  return await _storage.read(key: _keyWalletAddress);
}

// Add cleanup function for existing users
Future<void> deleteOldPrivateKeys() async {
  await _storage.delete(key: _keyPrivateKey);
  await _storage.delete(key: _keyMnemonic);
  print('🧹 Cleaned up old private keys for security');
}
```

---

### **Step 8: Update App Initialization**

Update `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AppKit
  await AppKitService.instance.initialize();
  
  // Clean up old private keys
  final storage = StorageService();
  await storage.deleteOldPrivateKeys();
  
  runApp(const CeloCredApp());
}
```

---

## 📱 User Experience Flow

### Before (INSECURE):
1. User enters private key ❌
2. App stores it ❌
3. App signs transactions automatically ❌
4. User has no idea what's happening ❌

### After (SECURE):
1. User clicks "Connect Wallet" ✅
2. QR code appears (or deep link to Valora) ✅
3. User approves connection in Valora ✅
4. User taps "Send Payment" ✅
5. Valora app opens automatically ✅
6. Valora shows: "Send 0.1 CELO to 0x742d35...?" ✅
7. User clicks "Approve" or "Reject" ✅
8. App receives result ✅
9. Success screen shows txHash ✅

---

## 🧪 Testing Plan

1. **Connect Wallet:**
   - Tap "Connect Wallet"
   - Scan QR with Valora
   - Approve connection
   - See wallet address displayed

2. **Merchant Registration:**
   - Fill form
   - Tap "Register"
   - Valora opens showing transaction
   - Approve in Valora
   - See success with txHash

3. **CELO Payment:**
   - Enter amount
   - Tap "Confirm"
   - Valora opens
   - Shows "Send 0.1 CELO..."
   - Approve
   - Payment succeeds

4. **cUSD Payment:**
   - Enter amount
   - Tap "Confirm"
   - Valora opens TWICE:
     1. "Approve PaymentProcessor?"
     2. "Send 10 cUSD?"
   - Approve both
   - Payment succeeds

5. **Loan Request:**
   - Fill loan form
   - Submit
   - Valora opens
   - Shows transaction
   - Approve
   - Loan created

6. **Rejection Test:**
   - Start any transaction
   - Valora opens
   - Click "Reject"
   - App shows "Transaction rejected"
   - No funds moved ✅

---

## 🚀 Deployment Checklist

Before going live:

- [ ] Get WalletConnect Project ID from cloud.reown.com
- [ ] Configure iOS Info.plist with wallet schemes
- [ ] Configure Android AndroidManifest.xml
- [ ] Test on real device with Valora installed
- [ ] Test connection flow
- [ ] Test all transaction types
- [ ] Test rejection flow
- [ ] Remove all private key related code
- [ ] Clear existing private keys from user devices
- [ ] Update security documentation

---

## 💡 Benefits After Implementation

1. **Security:** Private keys never leave user's wallet ✅
2. **Trust:** Users see exactly what they're signing ✅
3. **Standard:** Uses industry-standard WalletConnect protocol ✅
4. **Compliance:** Follows best practices for Web3 apps ✅
5. **Multi-Wallet:** Works with Valora, MetaMask, and 600+ wallets ✅
6. **User Control:** Users can reject suspicious transactions ✅

---

## ⚠️ Breaking Changes

**Existing users will need to:**
1. Reinstall/update app
2. Reconnect their wallet via WalletConnect
3. Old private key imports will be deleted for security

**This is NECESSARY for security!**

---

## 📚 References

- [Reown AppKit Docs](https://docs.reown.com/appkit/flutter/core/installation)
- [WalletConnect Protocol](https://walletconnect.com/)
- [Valora Deep Links](https://github.com/valora-inc/wallet/blob/main/docs/deeplinks.md)
- [Web3 Security Best Practices](https://ethereum.org/en/developers/docs/security/)

---

## ✅ Ready to Implement?

This is a **MAJOR** but **CRITICAL** fix. The changes are extensive but necessary for security.

**Estimated Time:** 2-3 hours for full implementation and testing

**Do you want me to proceed with implementation?** This will:
1. ✅ Fix the critical security vulnerability
2. ✅ Make your app production-ready
3. ✅ Follow industry best practices
4. ✅ Work like MetaMask/Valora properly

Let me know if you want to proceed or if you have questions about any step!
