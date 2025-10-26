import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/appkit_service.dart';
import '../auth/merchant_auth_screen.dart';
import '../payment/qr_scanner_screen.dart';
import '../payment/manual_payment_screen.dart';
import '../marketplace/loan_marketplace_screen.dart';

/// Connect Wallet Screen - Universal WalletConnect integration
class ConnectWalletScreen extends StatefulWidget {
  final String? nextRoute; // 'merchant', 'payment', 'marketplace'

  const ConnectWalletScreen({
    super.key,
    this.nextRoute,
  });

  @override
  State<ConnectWalletScreen> createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  final _storageService = StorageService();
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Wallet'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect Your Celo Wallet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap below to connect with Valora, MetaMask, or any WalletConnect-compatible wallet',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Network Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Celo Sepolia Testnet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // WalletConnect - Universal connection for all wallets
            _buildWalletOption(
              icon: Icons.qr_code_scanner,
              iconColor: Colors.blue,
              title: 'WalletConnect',
              subtitle: 'Connect with Valora, MetaMask, or any wallet',
              onTap: _connectWalletConnect,
            ),

            const SizedBox(height: 24),

            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                        size: 20, 
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Need a wallet?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Download Valora from App Store\n'
                    '• Create account and get free testnet tokens\n'
                    '• Return here to connect',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isConnecting ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _connectWalletConnect() async {
    setState(() => _isConnecting = true);

    try {
      // 🔐 SECURE: Initialize AppKit if not already initialized
      if (!context.mounted) return;
      try {
        await AppKitService.instance.initialize(context);
      } catch (e) {
        // Already initialized, continue
        debugPrint('AppKit already initialized: $e');
      }

      // Open WalletConnect modal - shows QR code or deep links to wallets
      final address = await AppKitService.instance.connect(context);

      if (address != null) {
        // Save wallet address (NOT private key!)
        await _storageService.saveWalletAddress(address);
        
        if (!mounted) return;

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Wallet connected: ${address.substring(0, 10)}...'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to appropriate screen
        _navigateToNextScreen(address);
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _navigateToNextScreen(String walletAddress) {
    Widget nextScreen;
    
    switch (widget.nextRoute) {
      case 'merchant':
        nextScreen = MerchantAuthScreen(walletAddress: walletAddress);
        break;
      case 'payment':
        nextScreen = const QRScannerScreen();
        break;
      case 'manual_payment':
        nextScreen = const ManualPaymentScreen();
        break;
      case 'marketplace':
        nextScreen = const LoanMarketplaceScreen();
        break;
      default:
        nextScreen = const QRScannerScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }
}
