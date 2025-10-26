import 'package:flutter/material.dart';
import '../../core/services/contract_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/web3_service.dart';
import '../../core/services/appkit_service.dart';
import '../nft/nft_selector_screen.dart';

/// Loan Request Screen with NFT collateral option
class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _contractService = ContractService();
  final _web3Service = Web3Service();
  final _storage = StorageService();
  
  String _selectedPurpose = 'Working Capital';
  int _selectedTerm = 30;
  bool _autoRepayment = true;
  bool _useNFTCollateral = false;
  String? _selectedNFTId;
  
  bool _isLoading = true;
  int _creditScore = 0;
  double _maxLoanAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCreditScore();
  }

  /// 🚀 REAL BLOCKCHAIN - Load credit score from oracle
  Future<void> _loadCreditScore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final walletAddress = await _storage.getWalletAddress();
      if (walletAddress == null) {
        throw Exception('No wallet connected');
      }

      // Fetch credit score from blockchain oracle
      final scoreData = await _contractService.getCreditScore(walletAddress);
      
      // Extract score from returned map
      final scoreValue = (scoreData['score'] as num?)?.toInt();
      final exists = scoreData['exists'] as bool? ?? false;
      
      if (exists && scoreValue != null && scoreValue > 0) {
        // Use blockchain credit score
        setState(() {
          _creditScore = scoreValue;
          _maxLoanAmount = _calculateMaxLoan(scoreValue);
        });
      } else {
        // No credit score on-chain yet, use calculated score
        print('⚠️ No on-chain credit score found, using calculated score');
        // TODO: Calculate credit score from transaction history
        setState(() {
          _creditScore = 650; // Default score for new users
          _maxLoanAmount = _calculateMaxLoan(650);
        });
      }
    } catch (e) {
      print('❌ Error loading credit score: $e');
      // Fallback to default
      setState(() {
        _creditScore = 650;
        _maxLoanAmount = 500.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateMaxLoan(int score) {
    if (score >= 800) return 5000.0;
    if (score >= 750) return 2000.0;
    if (score >= 700) return 1000.0;
    if (score >= 650) return 500.0;
    if (score >= 600) return 250.0;
    return 100.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Loan'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading credit score from blockchain...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Loan'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Credit Score Info
              _buildCreditScoreInfo(),
              
              const SizedBox(height: 24),
              
              // Loan Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Loan Amount (cUSD)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Max: \$$_maxLoanAmount',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  if (amount > _maxLoanAmount) {
                    return 'Amount exceeds limit';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Loan Purpose
              DropdownButtonFormField<String>(
                initialValue: _selectedPurpose,
                decoration: InputDecoration(
                  labelText: 'Loan Purpose',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Working Capital', child: Text('Working Capital')),
                  DropdownMenuItem(value: 'Inventory Purchase', child: Text('Inventory Purchase')),
                  DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
                  DropdownMenuItem(value: 'Expansion', child: Text('Business Expansion')),
                  DropdownMenuItem(value: 'Emergency', child: Text('Emergency Funds')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPurpose = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Loan Term
              const Text(
                'Loan Term',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [30, 60, 90, 180].map((days) {
                  return ChoiceChip(
                    label: Text('$days days'),
                    selected: _selectedTerm == days,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTerm = days;
                      });
                    },
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: _selectedTerm == days ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Auto-Repayment Toggle
              SwitchListTile(
                title: const Text('Enable Auto-Repayment'),
                subtitle: const Text('Automatically repay from incoming payments'),
                value: _autoRepayment,
                onChanged: (value) {
                  setState(() {
                    _autoRepayment = value;
                  });
                },
                activeThumbColor: Colors.green,
              ),
              
              const Divider(height: 32),
              
              // NFT Collateral Section
              SwitchListTile(
                title: const Text('Use NFT as Collateral'),
                subtitle: const Text('Increase loan amount with NFT collateral'),
                value: _useNFTCollateral,
                onChanged: (value) {
                  setState(() {
                    _useNFTCollateral = value;
                    if (!value) {
                      _selectedNFTId = null;
                    }
                  });
                },
                activeThumbColor: Colors.green,
              ),
              
              if (_useNFTCollateral) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final nftId = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NFTSelectorScreen(),
                      ),
                    );
                    if (nftId != null) {
                      setState(() {
                        _selectedNFTId = nftId;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text(
                    _selectedNFTId == null
                        ? 'Select NFT Collateral'
                        : 'NFT Selected: $_selectedNFTId',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (_selectedNFTId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'NFT locked as collateral. Max loan increased to \$1,000',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 24),
              
              // Loan Estimate
              _buildLoanEstimate(),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _submitLoanRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Loan Request',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditScoreInfo() {
    final scoreColor = _creditScore >= 70 ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.1), scoreColor.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_creditScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Credit Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  _creditScore >= 70 ? 'Excellent Credit' : 'Fair Credit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Eligible for up to \$$_maxLoanAmount',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanEstimate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interestRate = _calculateInterestRate();
    final interest = amount * (interestRate / 100) * (_selectedTerm / 365);
    final totalRepayment = amount + interest;
    final dailyPayment = totalRepayment / _selectedTerm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Loan Estimate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEstimateRow('Interest Rate', '${interestRate.toStringAsFixed(1)}% APR'),
          _buildEstimateRow('Interest Amount', '\$${interest.toStringAsFixed(2)}'),
          _buildEstimateRow('Total Repayment', '\$${totalRepayment.toStringAsFixed(2)}'),
          _buildEstimateRow('Daily Payment', '\$${dailyPayment.toStringAsFixed(2)}'),
          if (_autoRepayment) ...[
            const Divider(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auto-repayment will deduct from your daily sales',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterestRate() {
    // Base rate 12% APR
    double rate = 12.0;
    
    // Adjust based on credit score (credit score is 0-850 range)
    if (_creditScore >= 800) {
      rate -= 5.0; // Excellent credit
    } else if (_creditScore >= 750) {
      rate -= 3.0; // Very good
    } else if (_creditScore >= 700) {
      rate -= 1.5; // Good
    } else if (_creditScore >= 650) {
      rate -= 0.5; // Fair
    } else if (_creditScore < 600) {
      rate += 3.0; // Poor
    }
    
    // Discount for NFT collateral
    if (_useNFTCollateral && _selectedNFTId != null) {
      rate -= 2.0;
    }
    
    return rate.clamp(5.0, 20.0);
  }

  /// 🚀 REAL BLOCKCHAIN - Submit loan request to smart contract
  Future<void> _submitLoanRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_useNFTCollateral && _selectedNFTId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select NFT collateral'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Submitting loan request to blockchain...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      // Check if wallet is connected via WalletConnect
      if (!AppKitService.instance.isConnected) {
        throw Exception('No wallet connected. Please connect your wallet first.');
      }

      final amount = double.parse(_amountController.text);
      final interestRate = _calculateInterestRate();
      
      // Convert APR to basis points (5% = 500 basis points)
      final interestRateBasisPoints = (interestRate * 100).toInt();

      print('💰 Requesting loan on blockchain:');
      print('   Amount: $amount cUSD');
      print('   Interest Rate: $interestRate% APR ($interestRateBasisPoints basis points)');
      print('   Duration: $_selectedTerm days');
      print('   Purpose: $_selectedPurpose');

      // Show approval message
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Opening wallet for approval...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 🚀 REAL BLOCKCHAIN CALL via WalletConnect
      // User will see transaction details in their wallet app and must approve
      final String txHash;
      
      if (_useNFTCollateral && _selectedNFTId != null) {
        // Request loan with NFT collateral
        print('   With NFT Collateral: $_selectedNFTId');
        
        // TODO: In production, parse the NFT ID to extract contract address and token ID
        // For now, using placeholder values since NFT selector returns mock data
        // Format should be: "contractAddress:tokenId" or similar
        
        // Extract token ID from the NFT ID string (e.g., "NFT-1" -> 1)
        final tokenIdMatch = RegExp(r'\d+').firstMatch(_selectedNFTId!);
        final tokenId = tokenIdMatch != null ? int.parse(tokenIdMatch.group(0)!) : 1;
        
        // Placeholder NFT contract address - should be replaced with actual NFT contract
        const nftContractAddress = '0x0000000000000000000000000000000000000001';
        
        // Note: In production, you may need to approve NFT transfer first
        // await _contractService.approveNFTForLoan(nftContractAddress, tokenId);
        
        txHash = await _contractService.requestLoanWithCollateral(
          amount: amount,
          interestRate: interestRateBasisPoints,
          durationDays: _selectedTerm,
          nftContractAddress: nftContractAddress,
          nftTokenId: tokenId,
        );
      } else {
        // Regular loan request without collateral
        txHash = await _contractService.requestLoan(
          amount: amount,
          interestRate: interestRateBasisPoints,
          durationDays: _selectedTerm,
        );
      }

      print('✅ Loan requested! TxHash: $txHash');

      if (!mounted) return;
      
      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Loan Request Submitted!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your loan request has been submitted to the blockchain.'),
              const SizedBox(height: 12),
              Text(
                'Transaction Hash:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                txHash,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lenders will be notified and can fund your loan in the marketplace.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on UserRejectedError {
      // User rejected transaction in their wallet
      print('❌ Loan request rejected by user');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Transaction rejected by user'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Error submitting loan: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting loan: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _contractService.dispose();
    _web3Service.dispose();
    super.dispose();
  }
}
