import 'package:flutter/material.dart';
import '../../core/services/contract_service.dart';
import '../../core/services/web3_service.dart';
import '../../core/services/appkit_service.dart';

/// Loan Detail Screen for marketplace
class LoanDetailScreen extends StatefulWidget {
  final String loanId;
  final String merchantName;
  final int creditScore;
  final double loanAmount;
  final double interestRate;
  final int termDays;
  final double fundedAmount;
  final int lenderCount;
  final bool hasNFTCollateral;

  const LoanDetailScreen({
    super.key,
    required this.loanId,
    required this.merchantName,
    required this.creditScore,
    required this.loanAmount,
    required this.interestRate,
    required this.termDays,
    required this.fundedAmount,
    required this.lenderCount,
    this.hasNFTCollateral = false,
  });

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final _contractService = ContractService();
  final _web3Service = Web3Service();
  
  // ignore: unused_field
  bool _isFunding = false;
  // ignore: unused_field
  double _cUSDBalance = 0.0;

  @override
  Widget build(BuildContext context) {
    final fundingProgress = widget.fundedAmount / widget.loanAmount;
    final remainingAmount = widget.loanAmount - widget.fundedAmount;
    final scoreColor = widget.creditScore >= 70
        ? Colors.green
        : widget.creditScore >= 50
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Merchant Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.merchantName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.merchantName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Credit Score: ${widget.creditScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Loan Amount Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Loan Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${widget.loanAmount} cUSD',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Interest', '${widget.interestRate}%'),
                              _buildStatItem('Term', '${widget.termDays} days'),
                              _buildStatItem('Purpose', 'Working Capital'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Funding Progress
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Funding Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(fundingProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: fundingProgress,
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Funded: \$${widget.fundedAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Remaining: \$${remainingAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.lenderCount} lenders',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Collateral Section
                  if (widget.hasNFTCollateral)
                    Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.purple,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NFT Collateral',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'This loan is secured with NFT collateral',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.verified, color: Colors.purple),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Merchant Stats
                  const Text(
                    'Merchant History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildHistoryRow('Total Loans Repaid', '3'),
                          const Divider(height: 24),
                          _buildHistoryRow('On-Time Repayment Rate', '100%'),
                          const Divider(height: 24),
                          _buildHistoryRow('Time on Platform', '9 months'),
                          const Divider(height: 24),
                          _buildHistoryRow('Total Transactions', '156'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Fund Button
                  ElevatedButton(
                    onPressed: remainingAmount > 0 ? () => _showFundDialog(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      remainingAmount > 0 ? 'Fund This Loan' : 'Fully Funded',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Expected Return
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Expected Return',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.interestRate.toStringAsFixed(1)}% APR',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Interest paid automatically from sales',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showFundDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final remainingAmount = widget.loanAmount - widget.fundedAmount;
    
    // Load user's cUSD balance first
    double userBalance = 0.0;
    try {
      final walletAddress = AppKitService.instance.connectedAddress;
      if (walletAddress != null) {
        userBalance = await _web3Service.getCUSDBalance(walletAddress);
      }
    } catch (e) {
      print('Error loading balance: $e');
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
          final isValidAmount = enteredAmount > 0 && enteredAmount <= remainingAmount && enteredAmount <= userBalance;
          
          return AlertDialog(
            title: const Text('Fund This Loan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining: \$${remainingAmount.toStringAsFixed(2)} cUSD',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Balance: \$${userBalance.toStringAsFixed(2)} cUSD',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount to fund (cUSD)',
                    border: const OutlineInputBorder(),
                    helperText: 'Max: ${remainingAmount.toStringAsFixed(2)}',
                    suffixIcon: TextButton(
                      onPressed: () {
                        amountController.text = remainingAmount.toString();
                        setDialogState(() {});
                      },
                      child: const Text('MAX'),
                    ),
                  ),
                  onChanged: (value) => setDialogState(() {}),
                ),
                if (enteredAmount > userBalance && enteredAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Insufficient balance',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You will earn:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.interestRate.toStringAsFixed(1)}% interest',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isValidAmount ? () => _confirmFunding(context, enteredAmount) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fund Loan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmFunding(BuildContext dialogContext, double amount) async {
    // Close amount dialog
    Navigator.pop(dialogContext);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Funding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to fund this loan:'),
            const SizedBox(height: 12),
            Text(
              'Amount: \$${amount.toStringAsFixed(2)} cUSD',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Expected return: ${widget.interestRate.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will require 2 transactions:\n1. Approve cUSD\n2. Fund loan',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isFunding = true);

    try {
      // Step 1: Approve cUSD
      _showLoadingDialog('Step 1/2: Approving cUSD...');
      
      await _contractService.approveCUSDForLoan(amount);
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Step 2: Fund the loan
      _showLoadingDialog('Step 2/2: Funding loan...');
      
      final txHash = await _contractService.fundLoan(
        loanId: widget.loanId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              const Text('Funding Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have funded \$${amount.toStringAsFixed(2)} cUSD'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will earn ${widget.interestRate.toStringAsFixed(1)}% interest',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                'Transaction: $txHash',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to marketplace
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close any loading dialog
      Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name != null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fund loan: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFunding = false);
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 8),
              Text(
                'Please approve in your wallet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contractService.dispose();
    super.dispose();
  }
}
