import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../payment/qr_scanner_screen.dart';
import '../payment/manual_payment_screen.dart';
import '../marketplace/loan_marketplace_screen.dart';
import '../settings/clear_wallet_screen.dart';
import '../merchant/merchant_onboarding_screen.dart';
import '../merchant/merchant_dashboard_screen.dart';

/// New Home Screen - Wallet connection first, then access to all features
class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CeloCred'),
            backgroundColor: Colors.green,
            actions: [
              // Wallet Connection Button (Top Right)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: walletProvider.isConnected
                    ? _buildDisconnectButton(walletProvider)
                    : _buildConnectButton(walletProvider),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Logo
                    _buildLogo(),
                    
                    const SizedBox(height: 24),
                    
                    // App Name & Tagline
                    const Text(
                      'CeloCred',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Decentralized Credit for Small Businesses',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Wallet Status Banner
                    _buildWalletStatusBanner(walletProvider),
                    
                    const SizedBox(height: 32),
                    
                    // 4 Main Options
                    _buildMainOptions(walletProvider),
                    
                    const SizedBox(height: 32),
                    
                    // Footer
                    const Text(
                      'Built on Celo Blockchain',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Debug Settings (Remove in production)
                    if (walletProvider.isConnected)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClearWalletScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Debug Settings'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/logo/celocred_logo.png',
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 50,
              color: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectButton(WalletProvider walletProvider) {
    return ElevatedButton.icon(
      onPressed: _isConnecting
          ? null
          : () async {
              setState(() => _isConnecting = true);
              final success = await walletProvider.connectWallet(context);
              setState(() => _isConnecting = false);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Wallet connected: ${walletProvider.walletAddress?.substring(0, 10)}...',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connection cancelled or failed'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
      icon: _isConnecting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.account_balance_wallet, size: 20),
      label: Text(_isConnecting ? 'Connecting...' : 'Connect Wallet'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDisconnectButton(WalletProvider walletProvider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${walletProvider.walletAddress?.substring(0, 6)}...',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      onSelected: (value) async {
        if (value == 'disconnect') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Disconnect Wallet?'),
              content: const Text(
                'Are you sure you want to disconnect your wallet?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await walletProvider.disconnectWallet();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallet disconnected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'address',
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connected Wallet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                walletProvider.walletAddress ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              if (walletProvider.isMerchant) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '✓ Registered Merchant',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'disconnect',
          child: Row(
            children: [
              Icon(Icons.power_settings_new, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Disconnect'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletStatusBanner(WalletProvider walletProvider) {
    if (!walletProvider.isConnected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connect Your Wallet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your wallet to access all features',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isConnecting
                  ? null
                  : () async {
                      setState(() => _isConnecting = true);
                      await walletProvider.connectWallet(context);
                      setState(() => _isConnecting = false);
                    },
              icon: const Icon(Icons.link),
              label: const Text('Connect Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    // Connected - show wallet info
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Wallet Connected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${walletProvider.walletAddress?.substring(0, 10)}...${walletProvider.walletAddress?.substring(walletProvider.walletAddress!.length - 8)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
          if (walletProvider.isMerchant) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Registered Merchant',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainOptions(WalletProvider walletProvider) {
    return Column(
      children: [
        // Option 1: Scan to Pay
        _buildOptionCard(
          icon: Icons.qr_code_scanner,
          title: 'Scan to Pay',
          subtitle: 'Scan QR code to pay merchant',
          color: Colors.blue,
          isEnabled: walletProvider.isConnected,
          onTap: () => _handleOptionTap(
            walletProvider,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QRScannerScreen(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Option 2: Manual Payment
        _buildOptionCard(
          icon: Icons.account_balance_wallet,
          title: 'Manual Payment',
          subtitle: 'Enter wallet address to pay',
          color: Colors.purple,
          isEnabled: walletProvider.isConnected,
          onTap: () => _handleOptionTap(
            walletProvider,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManualPaymentScreen(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Option 3: Merchant Dashboard / Register
        _buildOptionCard(
          icon: walletProvider.isMerchant ? Icons.dashboard : Icons.store,
          title: walletProvider.isMerchant
              ? 'Merchant Dashboard'
              : 'Register as Merchant',
          subtitle: walletProvider.isMerchant
              ? 'Manage your business'
              : 'Start accepting payments',
          color: Colors.green,
          isEnabled: walletProvider.isConnected,
          badge: walletProvider.isMerchant ? '✓' : null,
          onTap: () => _handleOptionTap(
            walletProvider,
            () => _navigateToMerchant(walletProvider),
          ),
        ),

        const SizedBox(height: 16),

        // Option 4: Loan Marketplace
        _buildOptionCard(
          icon: Icons.account_balance,
          title: 'Loan Marketplace',
          subtitle: 'Fund loans and earn interest',
          color: Colors.orange,
          isEnabled: walletProvider.isConnected,
          onTap: () => _handleOptionTap(
            walletProvider,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoanMarketplaceScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled ? Colors.grey.shade200 : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 14,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOptionTap(WalletProvider walletProvider, VoidCallback action) {
    if (!walletProvider.isConnected) {
      // Show prompt to connect wallet first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connect Wallet First'),
          content: const Text(
            'Please connect your wallet to access this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isConnecting = true);
                await walletProvider.connectWallet(context);
                setState(() => _isConnecting = false);
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Connect Wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Wallet is connected, proceed with action
    action();
  }

  void _navigateToMerchant(WalletProvider walletProvider) {
    if (walletProvider.isMerchant) {
      // Navigate to Merchant Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MerchantDashboardScreen(
            businessName: 'Business', // This will be fetched from Firebase
          ),
        ),
      );
    } else {
      // Navigate to Merchant Onboarding
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MerchantOnboardingScreen(),
        ),
      );
    }
  }
}
