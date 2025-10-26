import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data
/// SECURITY FIX: Private keys removed - now only stores wallet addresses!
class StorageService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _keyPrivateKey = 'private_key'; // ⚠️ DEPRECATED - for cleanup only
  static const _keyMnemonic = 'mnemonic'; // ⚠️ DEPRECATED - for cleanup only
  static const _keyWalletAddress = 'wallet_address';
  static const _keyMerchantId = 'merchant_id';
  static const _keyUserType = 'user_type';
  static const _keyIsLoggedIn = 'is_logged_in';

  // ❌ REMOVED FOR SECURITY: savePrivateKey(), getPrivateKey(), saveMnemonic(), getMnemonic()
  // Wallet now connects via WalletConnect - private keys NEVER stored in app!

  // Wallet Address (safe to store)
  Future<void> saveWalletAddress(String address) async {
    await _storage.write(key: _keyWalletAddress, value: address);
  }

  Future<String?> getWalletAddress() async {
    return await _storage.read(key: _keyWalletAddress);
  }

  // Merchant
  Future<void> saveMerchantId(String merchantId) async {
    await _storage.write(key: _keyMerchantId, value: merchantId);
  }

  Future<String?> getMerchantId() async {
    return await _storage.read(key: _keyMerchantId);
  }

  Future<void> saveUserType(String userType) async {
    await _storage.write(key: _keyUserType, value: userType);
  }

  Future<String?> getUserType() async {
    return await _storage.read(key: _keyUserType);
  }

  Future<void> setLoggedIn(bool value) async {
    await _storage.write(key: _keyIsLoggedIn, value: value.toString());
  }

  Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _keyIsLoggedIn);
    return value == 'true';
  }

  // Check if wallet exists
  Future<bool> hasWallet() async {
    final address = await getWalletAddress();
    return address != null && address.isNotEmpty;
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear wallet data only
  Future<void> clearWallet() async {
    await _storage.delete(key: _keyPrivateKey); // Clean up old keys
    await _storage.delete(key: _keyMnemonic); // Clean up old keys
    await _storage.delete(key: _keyWalletAddress);
  }

  // 🧹 Clean up old insecure private keys (run on app startup)
  Future<void> deleteOldPrivateKeys() async {
    try {
      await _storage.delete(key: _keyPrivateKey);
      await _storage.delete(key: _keyMnemonic);
      print('🧹 Cleaned up old private keys for security');
    } catch (e) {
      print('⚠️ Error cleaning up old keys: $e');
    }
  }
}
