import 'package:flutter/material.dart';
import '../wallet/connect_wallet_screen.dart';
import '../settings/clear_wallet_screen.dart';

/// Home Screen - Entry point for all users
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CeloCred'),
        backgroundColor: Colors.green,
        actions: [
          // Debug: Clear wallet button (remove in production)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Clear Wallet (Testing)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClearWalletScreen(),
                ),
              );
            },
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
                const SizedBox(height: 40),
                
                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo/celocred_logo.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 60,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
                
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
                
                const SizedBox(height: 40),
                
                // Live Statistics Banner
                _buildStatsCard(),
                
                const SizedBox(height: 40),
                
                // Action Buttons
                _buildActionButton(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: 'Pay Merchant',
                  subtitle: 'Scan QR to pay with cUSD',
                  color: Colors.blue,
                  onTap: () => _navigateToQRScanner(context),
                ),
                
                const SizedBox(height: 16),
                
                _buildActionButton(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Manual Payment',
                  subtitle: 'Enter merchant address to send payment',
                  color: Colors.purple,
                  onTap: () => _navigateToManualPayment(context),
                ),
                
                const SizedBox(height: 16),
                
                _buildActionButton(
                  context,
                  icon: Icons.store,
                  title: 'I\'m a Merchant',
                  subtitle: 'Register or login to your dashboard',
                  color: Colors.green,
                  onTap: () => _navigateToMerchantAuth(context),
                ),
                
                const SizedBox(height: 16),
                
                _buildActionButton(
                  context,
                  icon: Icons.account_balance,
                  title: 'Explore Loans',
                  subtitle: 'Fund merchant loans and earn interest',
                  color: Colors.orange,
                  onTap: () => _navigateToMarketplace(context),
                ),
                
                const SizedBox(height: 40),
                
                // Footer
                const Text(
                  'Built on Celo Blockchain',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
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
          const Text(
            'Platform Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Merchants', '1,234'),
              _buildStatItem('Loans', '456'),
              _buildStatItem('Volume', '\$890K'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Average Credit Score: 68/100',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToQRScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectWalletScreen(nextRoute: 'payment'),
      ),
    );
  }

  void _navigateToManualPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectWalletScreen(nextRoute: 'manual_payment'),
      ),
    );
  }

  void _navigateToMerchantAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectWalletScreen(nextRoute: 'merchant'),
      ),
    );
  }

  void _navigateToMarketplace(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectWalletScreen(nextRoute: 'marketplace'),
      ),
    );
  }
}
