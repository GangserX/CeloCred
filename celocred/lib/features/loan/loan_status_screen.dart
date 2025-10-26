import 'package:flutter/material.dart';

/// Loan Status Screen - shows approval/rejection status
class LoanStatusScreen extends StatelessWidget {
  final double loanAmount;
  final bool isApproved;

  const LoanStatusScreen({
    super.key,
    required this.loanAmount,
    required this.isApproved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Request Status'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApproved ? Icons.check_circle : Icons.hourglass_empty,
                  size: 100,
                  color: isApproved ? Colors.green : Colors.orange,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status Title
              Text(
                isApproved
                    ? 'Loan Approved! 🎉'
                    : 'Under Review',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Amount
              Text(
                '\$${loanAmount.toStringAsFixed(2)} cUSD',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isApproved ? Colors.green : Colors.orange,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Status Message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isApproved
                      ? 'Your excellent credit score qualifies you for instant approval! The loan will be disbursed to your wallet shortly.'
                      : 'Your loan request is being reviewed by our community of lenders. This typically takes 24-48 hours. We\'ll notify you once funding is available.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Next Steps
              if (isApproved) ...[
                const Text(
                  'Next Steps:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Funds will be transferred to your wallet'),
                _buildStep('2', 'Start repaying through daily sales'),
                _buildStep('3', 'Track progress in the Loans tab'),
              ] else ...[
                const Text(
                  'What\'s Next:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Loan listed on marketplace'),
                _buildStep('2', 'Community members can fund'),
                _buildStep('3', 'You\'ll be notified when fully funded'),
              ],
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back to Dashboard'),
                    ),
                  ),
                  if (!isApproved) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // View in marketplace
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('View in Marketplace'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
