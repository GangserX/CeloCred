import 'package:flutter/material.dart';
import '../../core/models/loan_model.dart';
import '../../core/services/contract_service.dart';
import '../../core/services/web3_service.dart';
import '../../core/services/appkit_service.dart';

/// Loan Repayment Screen - Allows borrowers to repay their loans
class LoanRepaymentScreen extends StatefulWidget {
  final Loan loan;

  const LoanRepaymentScreen({
    super.key,
    required this.loan,
  });

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  final _contractService = ContractService();
  final _web3Service = Web3Service();
  
  bool _isRepaying = false;
  bool _isLoadingBalance = true;
  double _cUSDBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);

    try {
      final walletAddress = AppKitService.instance.connectedAddress;
      
      if (walletAddress == null) {
        throw Exception('Wallet not connected');
      }

      final balance = await _web3Service.getCUSDBalance(walletAddress);
      
      setState(() {
        _cUSDBalance = balance;
        _isLoadingBalance = false;
      });
    } catch (e) {
      print('❌ Error loading balance: $e');
      setState(() => _isLoadingBalance = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load balance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _interestAmount => widget.loan.amount * widget.loan.interestRate / 100;
  double get _totalRepayment => widget.loan.totalRepaymentAmount;
  bool get _hasSufficientBalance => _cUSDBalance >= _totalRepayment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repay Loan'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingBalance
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Loan Details Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loan Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Loan Amount', '${widget.loan.amount.toStringAsFixed(2)} cUSD'),
                          _buildDetailRow('Interest Rate', '${widget.loan.interestRate}%'),
                          _buildDetailRow('Interest Amount', '${_interestAmount.toStringAsFixed(2)} cUSD'),
                          _buildDetailRow('Term', '${widget.loan.termDays} days'),
                          if (widget.loan.dueDate != null)
                            _buildDetailRow(
                              'Due Date',
                              '${widget.loan.dueDate!.day}/${widget.loan.dueDate!.month}/${widget.loan.dueDate!.year}',
                            ),
                          if (widget.loan.isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Loan is overdue!',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (widget.loan.hasCollateral)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'NFT collateral will be returned after repayment',
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Repayment Summary Card
                  Card(
                    elevation: 4,
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repayment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Repayment:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_totalRepayment.toStringAsFixed(2)} cUSD',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your cUSD Balance:'),
                                Text(
                                  '${_cUSDBalance.toStringAsFixed(2)} cUSD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _hasSufficientBalance ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_hasSufficientBalance)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Insufficient balance. You need ${(_totalRepayment - _cUSDBalance).toStringAsFixed(2)} more cUSD',
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Repayment Process Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Repayment Process',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildProcessStep('1', 'Approve cUSD spending'),
                          _buildProcessStep('2', 'Repay loan to lender'),
                          if (widget.loan.hasCollateral)
                            _buildProcessStep('3', 'Receive NFT collateral back'),
                          const SizedBox(height: 8),
                          Text(
                            'You will need to approve 2 transactions in your wallet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Repay Button
                  ElevatedButton(
                    onPressed: _isRepaying || !_hasSufficientBalance ? null : _repayLoan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isRepaying
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Repaying Loan...', style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text(
                            'Repay Loan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _repayLoan() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Repayment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to repay this loan:'),
            const SizedBox(height: 12),
            Text(
              'Amount: ${_totalRepayment.toStringAsFixed(2)} cUSD',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will require 2 transactions:\n1. Approve cUSD\n2. Repay loan',
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
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRepaying = true);

    try {
      // Step 1: Approve cUSD spending
      _showLoadingDialog('Step 1/2: Approving cUSD...');
      
      await _contractService.approveCUSDForLoan(_totalRepayment);
      
      // Small delay to let approval transaction confirm
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Step 2: Repay loan
      _showLoadingDialog('Step 2/2: Repaying loan...');
      
      final txHash = await _contractService.repayLoan(
        loanId: widget.loan.id,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              const Text('Loan Repaid!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your loan has been successfully repaid!'),
              const SizedBox(height: 16),
              if (widget.loan.hasCollateral)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your NFT collateral has been returned',
                          style: TextStyle(fontSize: 13),
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
                Navigator.pop(context, true); // Return to previous screen with success
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close any open loading dialog
      Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name != null);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to repay loan: ${e.toString()}'),
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
        setState(() => _isRepaying = false);
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
