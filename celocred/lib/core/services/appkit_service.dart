import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../constants/celo_config.dart';

/// WalletConnect service using Reown AppKit
/// This handles secure wallet connections WITHOUT ever seeing private keys
class AppKitService {
  static AppKitService? _instance;
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;

  static AppKitService get instance {
    _instance ??= AppKitService._();
    return _instance!;
  }

  AppKitService._();

  /// Check if AppKit is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize AppKit with WalletConnect
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
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
        // Configure for Celo Sepolia testnet
        requiredNamespaces: {
          'eip155': RequiredNamespace(
            chains: [
              'eip155:${CeloConfig.celoTestnetChainId}', // Celo Sepolia testnet
            ],
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
        optionalNamespaces: {
          'eip155': RequiredNamespace(
            chains: ['eip155:42220'], // Celo Mainnet (optional)
            methods: [
              'eth_sendTransaction',
              'eth_call',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      // Configure for Celo Sepolia testnet
      await _appKitModal!.init();
      _isInitialized = true;
      
      debugPrint('✅ AppKit initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AppKit: $e');
      rethrow;
    }
  }

  /// Open WalletConnect modal to connect wallet
  Future<String?> connect(BuildContext context) async {
    if (!_isInitialized) {
      await initialize(context);
    }

    try {
      await _appKitModal!.openModalView();
      
      // Wait for connection
      if (_appKitModal!.isConnected) {
        final session = _appKitModal!.session;
        // Get first account from session
        final address = session?.getAccounts()?.firstOrNull;
        debugPrint('✅ Wallet connected: $address');
        return address?.split(':').last; // Extract address from CAIP-10 format (eip155:11142220:0x...)
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error connecting wallet: $e');
      return null;
    }
  }

  /// Get connected wallet address
  String? get connectedAddress {
    final accounts = _appKitModal?.session?.getAccounts();
    if (accounts != null && accounts.isNotEmpty) {
      // Extract address from CAIP-10 format
      return accounts.first.split(':').last;
    }
    return null;
  }

  /// Check if wallet is connected
  bool get isConnected {
    return _appKitModal?.isConnected ?? false;
  }

  /// Get the current chainId
  Future<int?> getCurrentChainId() async {
    if (!isConnected) return null;

    try {
      final session = _appKitModal!.session;
      if (session == null) return null;

      final result = await _appKitModal!.request(
        topic: session.topic,
        chainId: 'eip155:${CeloConfig.celoTestnetChainId}',
        request: SessionRequestParams(
          method: 'eth_chainId',
          params: [],
        ),
      );

      // Result is a hex string like "0xaef3"
      final chainIdHex = result.toString();
      return int.parse(chainIdHex.substring(2), radix: 16);
    } catch (e) {
      debugPrint('❌ Error getting chain ID: $e');
      return null;
    }
  }

  /// Switch to a specific chain
  Future<bool> switchChain(int chainId) async {
    if (!isConnected) return false;

    try {
      final session = _appKitModal!.session;
      if (session == null) return false;

      // Format chain ID as hex string
      final chainIdHex = '0x${chainId.toRadixString(16)}';

      await _appKitModal!.request(
        topic: session.topic,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'wallet_switchEthereumChain',
          params: [{'chainId': chainIdHex}],
        ),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error switching chain: $e');
      return false;
    }
  }

  /// Disconnect wallet
  Future<void> disconnect() async {
    if (_appKitModal != null && isConnected) {
      await _appKitModal!.disconnect();
      debugPrint('🔌 Wallet disconnected');
    }
  }

  /// Send a transaction (user approves in their wallet)
  /// This is SECURE - private key never leaves user's wallet!
  Future<String> sendTransaction({
    required String to,
    required BigInt value,
    String? data,
    BigInt? gas,
    bool isPaymentTransaction = false, // Kept for backward compatibility
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected. Please connect your wallet first.');
    }

    try {
      debugPrint('📤 Sending transaction to wallet for approval...');
      debugPrint('   To: $to');
      debugPrint('   Value: $value Wei');
      debugPrint('   Data: ${data ?? "0x"}');

      final session = _appKitModal!.session;
      if (session == null) {
        throw Exception('No active session');
      }

      // Build transaction
      final tx = {
        'from': connectedAddress,
        'to': to,
        'value': '0x${value.toRadixString(16)}',
        'data': data ?? '0x',
        'gas': gas != null ? '0x${gas.toRadixString(16)}' : '0x7A120', // 500k default
      };

      // Send to wallet for signing (USER APPROVES HERE!)
      // All transactions now use Sepolia testnet
      final result = await _appKitModal!.request(
        topic: session.topic,
        chainId: 'eip155:${CeloConfig.celoTestnetChainId}',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [tx],
        ),
      );

      final txHash = result.toString();
      debugPrint('✅ Transaction approved and sent! TxHash: $txHash');
      return txHash;
    } on UserRejectedError {
      debugPrint('❌ User rejected transaction in wallet');
      throw Exception('Transaction rejected by user');
    } catch (e) {
      debugPrint('❌ Error sending transaction: $e');
      rethrow;
    }
  }

  /// Call a contract function (for read-only operations)
  Future<dynamic> call({
    required String to,
    required String data,
    bool isPaymentTransaction = false, // Kept for backward compatibility
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      final session = _appKitModal!.session;
      if (session == null) {
        throw Exception('No active session');
      }

      // All operations use Sepolia testnet
      final result = await _appKitModal!.request(
        topic: session.topic,
        chainId: 'eip155:${CeloConfig.celoTestnetChainId}',
        request: SessionRequestParams(
          method: 'eth_call',
          params: [
            {
              'from': connectedAddress,
              'to': to,
              'data': data,
            },
            'latest',
          ],
        ),
      );

      return result;
    } catch (e) {
      debugPrint('❌ Error calling contract: $e');
      rethrow;
    }
  }

  /// Sign a message (for authentication, etc.)
  Future<String> signMessage(String message, {bool isPaymentTransaction = false}) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      final session = _appKitModal!.session;
      if (session == null) {
        throw Exception('No active session');
      }

      // All operations use Sepolia testnet
      final result = await _appKitModal!.request(
        topic: session.topic,
        chainId: 'eip155:${CeloConfig.celoTestnetChainId}',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [message, connectedAddress],
        ),
      );

      return result.toString();
    } on UserRejectedError {
      throw Exception('Signature rejected by user');
    } catch (e) {
      debugPrint('❌ Error signing message: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _appKitModal = null;
    _isInitialized = false;
  }
}

/// Custom exception for user rejection
class UserRejectedError implements Exception {
  final String message;
  UserRejectedError([this.message = 'User rejected the request']);

  @override
  String toString() => message;
}
