import 'package:flutter/material.dart';
import '../services/appkit_service.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

/// Wallet State Provider - Manages wallet connection state across the app
class WalletProvider with ChangeNotifier {
  static WalletProvider? _instance;
  static WalletProvider get instance {
    _instance ??= WalletProvider._();
    return _instance!;
  }

  WalletProvider._();

  final _storage = StorageService();
  final _firebase = FirebaseService.instance;

  String? _walletAddress;
  bool _isConnected = false;
  bool _isMerchant = false;
  bool _isCheckingMerchant = false;

  // Getters
  String? get walletAddress => _walletAddress;
  bool get isConnected => _isConnected;
  bool get isMerchant => _isMerchant;
  bool get isCheckingMerchant => _isCheckingMerchant;

  /// Initialize wallet state from storage
  Future<void> initialize() async {
    try {
      // Check if wallet is already connected (from WalletConnect)
      final connectedAddress = AppKitService.instance.connectedAddress;
      
      if (connectedAddress != null) {
        _walletAddress = connectedAddress;
        _isConnected = true;
        await _checkMerchantStatus(connectedAddress);
        notifyListeners();
        return;
      }

      // Fallback: check stored wallet address
      final storedAddress = await _storage.getWalletAddress();
      if (storedAddress != null && storedAddress.isNotEmpty) {
        _walletAddress = storedAddress;
        _isConnected = false; // Not actively connected via WalletConnect
        await _checkMerchantStatus(storedAddress);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error initializing wallet state: $e');
    }
  }

  /// Connect wallet via WalletConnect
  Future<bool> connectWallet(BuildContext context) async {
    try {
      // Initialize AppKit if not already done
      if (!context.mounted) return false;
      
      try {
        await AppKitService.instance.initialize(context);
      } catch (e) {
        debugPrint('AppKit already initialized: $e');
      }

      // Open WalletConnect modal
      final address = await AppKitService.instance.connect(context);

      if (address != null) {
        _walletAddress = address;
        _isConnected = true;

        // Save to storage
        await _storage.saveWalletAddress(address);

        // Update last login in Firebase
        await _firebase.updateLastLogin(address);

        // Check merchant status
        await _checkMerchantStatus(address);

        notifyListeners();
        
        print('✅ Wallet connected: ${address.substring(0, 10)}...');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error connecting wallet: $e');
      return false;
    }
  }

  /// Check if the connected wallet is a registered merchant
  Future<void> _checkMerchantStatus(String address) async {
    _isCheckingMerchant = true;
    notifyListeners();

    try {
      _isMerchant = await _firebase.isMerchant(address);
      print(_isMerchant 
        ? '✅ Wallet is a registered merchant' 
        : 'ℹ️ Wallet is not a merchant'
      );
    } catch (e) {
      print('❌ Error checking merchant status: $e');
      _isMerchant = false;
    } finally {
      _isCheckingMerchant = false;
      notifyListeners();
    }
  }

  /// Disconnect wallet
  Future<void> disconnectWallet() async {
    try {
      // Disconnect from WalletConnect
      if (AppKitService.instance.isConnected) {
        await AppKitService.instance.disconnect();
      }

      // Clear stored wallet data
      await _storage.clearWallet();

      _walletAddress = null;
      _isConnected = false;
      _isMerchant = false;

      notifyListeners();
      
      print('🔌 Wallet disconnected');
    } catch (e) {
      print('❌ Error disconnecting wallet: $e');
    }
  }

  /// Refresh merchant status (call after merchant registration)
  Future<void> refreshMerchantStatus() async {
    if (_walletAddress != null) {
      await _checkMerchantStatus(_walletAddress!);
    }
  }

  /// Check if wallet needs reconnection
  bool needsConnection() {
    return !_isConnected || _walletAddress == null;
  }
}
