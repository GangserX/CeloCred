import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletConnectService {
  static final WalletConnectService _instance = WalletConnectService._internal();
  factory WalletConnectService() => _instance;
  WalletConnectService._internal();

  final _storage = const FlutterSecureStorage();
  String? _connectedAddress;
  String? _connectedWalletType; // 'valora', 'metamask', or 'manual'
  
  // Valora deep links
  static const String valoraDeepLink = 'celo://wallet';
  static const String valoraPlayStoreUrl = 'https://play.google.com/store/apps/details?id=co.clabs.valora';
  static const String valoraAppStoreUrl = 'https://apps.apple.com/app/valora/id1520414263';
  
  // MetaMask deep links
  static const String metaMaskDeepLink = 'metamask://';
  static const String metaMaskPlayStoreUrl = 'https://play.google.com/store/apps/details?id=io.metamask';
  static const String metaMaskAppStoreUrl = 'https://apps.apple.com/app/metamask/id1438144202';

  String? get connectedAddress => _connectedAddress;
  String? get connectedWalletType => _connectedWalletType;
  bool get isConnected => _connectedAddress != null;

  /// Load saved wallet connection from storage
  Future<bool> loadSavedConnection() async {
    try {
      _connectedAddress = await _storage.read(key: 'wallet_address');
      _connectedWalletType = await _storage.read(key: 'wallet_type');
      return _connectedAddress != null;
    } catch (e) {
      debugPrint('Error loading wallet connection: $e');
      return false;
    }
  }

  /// Save wallet connection to storage
  Future<void> saveConnection(String address, String walletType) async {
    _connectedAddress = address;
    _connectedWalletType = walletType;
    await _storage.write(key: 'wallet_address', value: address);
    await _storage.write(key: 'wallet_type', value: walletType);
    debugPrint('✅ Wallet saved: $address ($walletType)');
  }

  /// Connect to Valora wallet via deep link
  Future<bool> connectValora({
    required BuildContext context,
    required Function(String address) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      // Check if Valora is installed
      final valoraUri = Uri.parse(valoraDeepLink);
      final canLaunchValora = await canLaunchUrl(valoraUri);
      
      if (!canLaunchValora) {
        if (context.mounted) {
          final shouldInstall = await _showInstallDialog(
            context,
            'Install Valora Wallet',
            'Valora is the best wallet for Celo. It\'s free and takes 1 minute to set up.',
            valoraPlayStoreUrl,
          );
          
          if (shouldInstall) {
            // User will install Valora, return false to indicate connection incomplete
            return false;
          } else {
            onError('Valora wallet is required');
            return false;
          }
        }
        return false;
      }

      // Launch Valora app
      await launchUrl(valoraUri, mode: LaunchMode.externalApplication);
      
      // Show instruction dialog
      if (context.mounted) {
        await _showWalletInstructionDialog(
          context,
          'Connect Valora Wallet',
          'Steps to connect:\n\n'
          '1. Valora app is now opening\n'
          '2. Copy your wallet address from Valora\n'
          '3. Return to CeloCred\n'
          '4. Paste your address in the manual input field\n\n'
          'Your address starts with "0x" and is 42 characters long.',
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Valora connection error: $e');
      onError(e.toString());
      return false;
    }
  }

  /// Connect to MetaMask wallet via deep link
  Future<bool> connectMetaMask({
    required BuildContext context,
    required Function(String address) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      // Check if MetaMask is installed
      final metaMaskUri = Uri.parse(metaMaskDeepLink);
      final canLaunchMM = await canLaunchUrl(metaMaskUri);
      
      if (!canLaunchMM) {
        if (context.mounted) {
          final shouldInstall = await _showInstallDialog(
            context,
            'Install MetaMask',
            'MetaMask is a popular Web3 wallet. Make sure to add Celo network after installation.',
            metaMaskPlayStoreUrl,
          );
          
          if (shouldInstall) {
            return false;
          } else {
            onError('MetaMask is required');
            return false;
          }
        }
        return false;
      }

      // Launch MetaMask app
      await launchUrl(metaMaskUri, mode: LaunchMode.externalApplication);
      
      // Show instruction dialog
      if (context.mounted) {
        await _showWalletInstructionDialog(
          context,
          'Connect MetaMask',
          'Steps to connect:\n\n'
          '1. MetaMask app is now opening\n'
          '2. Add Celo Sepolia network if not added:\n'
          '   - Network: Celo Sepolia Testnet\n'
          '   - RPC: https://forno.celo-sepolia.celo-testnet.org\n'
          '   - Chain ID: 11142220\n'
          '   - Currency: CELO\n'
          '   - Block Explorer: https://celo-sepolia.blockscout.com\n'
          '3. Copy your wallet address\n'
          '4. Return to CeloCred\n'
          '5. Paste your address in the manual input field',
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ MetaMask connection error: $e');
      onError(e.toString());
      return false;
    }
  }

  /// Show install dialog for wallet apps
  Future<bool> _showInstallDialog(
    BuildContext context,
    String title,
    String message,
    String downloadUrl,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            onPressed: () async {
              Navigator.pop(context, true);
              final url = Uri.parse(downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show wallet instruction dialog
  Future<void> _showWalletInstructionDialog(
    BuildContext context,
    String title,
    String instructions,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(instructions),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Disconnect wallet
  Future<void> disconnect() async {
    _connectedAddress = null;
    _connectedWalletType = null;
    await _storage.delete(key: 'wallet_address');
    await _storage.delete(key: 'wallet_type');
    debugPrint('🔌 Wallet disconnected');
  }

  /// Check if wallet app is installed
  Future<bool> isWalletInstalled(String walletType) async {
    switch (walletType.toLowerCase()) {
      case 'valora':
        return await canLaunchUrl(Uri.parse(valoraDeepLink));
      case 'metamask':
        return await canLaunchUrl(Uri.parse(metaMaskDeepLink));
      default:
        return false;
    }
  }

  /// Validate Celo address format
  bool isValidCeloAddress(String address) {
    // Celo addresses are Ethereum-compatible: 0x followed by 40 hex characters
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }
}
