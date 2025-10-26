import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Payment Success Screen
class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String token;
  final String merchantName;
  final String txHash;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.token,
    required this.merchantName,
    required this.txHash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Complete'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Animation
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Payment Successful! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You paid $merchantName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Amount Card
              Container(
                padding: const EdgeInsets.all(24),
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
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Amount Paid',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$amount $token',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Transaction Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Transaction Hash',
                      '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}',
                      icon: Icons.receipt_long,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: txHash));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction hash copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Date & Time',
                      _formatDateTime(DateTime.now()),
                      icon: Icons.access_time,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Network',
                      'Celo Sepolia',
                      icon: Icons.network_check,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewOnExplorer(context),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View on Explorer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Reward Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This payment improves your credit score!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.copy, size: 16, color: Colors.black54),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _viewOnExplorer(BuildContext context) async {
    final url = 'https://celo-sepolia.blockscout.com/tx/$txHash';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open explorer')),
        );
      }
    }
  }
}
