import 'package:flutter/material.dart';
import 'payment_success_screen.dart';
import '../../core/services/web3_service.dart';
import '../../core/services/contract_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/appkit_service.dart';

/// Payment Confirmation Screen
class PaymentConfirmationScreen extends StatefulWidget {
  final String merchantName;
  final String merchantAddress;
  final String merchantCategory;

  const PaymentConfirmationScreen({
    super.key,
    required this.merchantName,
    required this.merchantAddress,
    required this.merchantCategory,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _web3Service = Web3Service();
  final _contractService = ContractService();
  final _storage = StorageService();
  
  String _selectedToken = 'cUSD';
  bool _isProcessing = false;
  bool _isLoadingBalances = true;

  // Real balances from blockchain
  Map<String, double> _balances = {
    'cUSD': 0.0,
    'cEUR': 0.0,
    'CELO': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    try {
      // First try to get address from WalletConnect (most recent connection)
      String? walletAddress = AppKitService.instance.connectedAddress;
      
      // Fallback to stored address if WalletConnect not active
      walletAddress ??= await _storage.getWalletAddress();
      
      if (walletAddress == null) {
        throw Exception('No wallet connected');
      }

      print('🔍 Checking balances for address: $walletAddress');

      // 🚀 REAL BLOCKCHAIN CALLS - Fetch actual balances
      final celoBalance = await _web3Service.getCeloBalance(walletAddress);
      final cusdBalance = await _web3Service.getCUSDBalance(walletAddress);
      final ceurBalance = await _web3Service.getCEURBalance(walletAddress);

      setState(() {
        _balances = {
          'CELO': celoBalance,
          'cUSD': cusdBalance,
          'cEUR': ceurBalance,
        };
        _isLoadingBalances = false;
      });

      print('✅ Loaded real balances for $walletAddress:');
      print('   CELO=$celoBalance, cUSD=$cusdBalance, cEUR=$ceurBalance');
    } catch (e) {
      print('❌ Error loading balances: $e');
      setState(() {
        _isLoadingBalances = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load balances: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment'),
        backgroundColor: Colors.green,
      ),
      body: _isLoadingBalances
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Loading wallet balances...'),
                ],
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Merchant Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          widget.merchantName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.merchantCategory,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Credit Score: 78',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Amount Input
              const Text(
                'Payment Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money, size: 32),
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  if (amount > (_balances[_selectedToken] ?? 0)) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Token Selector
              const Text(
                'Select Token',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _balances.keys.map((token) {
                  final isSelected = _selectedToken == token;
                  return ChoiceChip(
                    label: Column(
                      children: [
                        Text(
                          token,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          _balances[token]!.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedToken = token;
                      });
                    },
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Transaction Details
              Container(
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
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Network', 'Celo Alfajores'),
                    _buildDetailRow('Gas Fee', '~0.001 CELO'),
                    _buildDetailRow('Estimated Time', '~5 seconds'),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'To Address',
                      '${widget.merchantAddress.substring(0, 6)}...${widget.merchantAddress.substring(widget.merchantAddress.length - 4)}',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Confirm Button
              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if wallet is connected via WalletConnect
      if (!AppKitService.instance.isConnected) {
        throw Exception('No wallet connected. Please connect your wallet first.');
      }

      final amount = double.parse(_amountController.text);
      final currentBalance = _balances[_selectedToken] ?? 0.0;
      
      // Check for sufficient funds INCLUDING gas
      if (_selectedToken == 'CELO') {
        // For CELO payments, need amount + gas (~0.002 CELO buffer)
        if (amount + 0.002 > currentBalance) {
          throw Exception(
            'Insufficient CELO for payment + gas.\n'
            'Need: ${(amount + 0.002).toStringAsFixed(4)} CELO\n'
            'Have: ${currentBalance.toStringAsFixed(4)} CELO\n\n'
            'Try sending less, or get more CELO from faucet:\n'
            'https://faucet.celo.org'
          );
        }
      } else {
        // For token payments, need separate CELO for gas
        final celoBalance = _balances['CELO'] ?? 0.0;
        if (celoBalance < 0.002) {
          throw Exception(
            'Insufficient CELO for gas fees.\n'
            'Need: 0.002 CELO for gas\n'
            'Have: ${celoBalance.toStringAsFixed(4)} CELO\n\n'
            'Get CELO from faucet:\n'
            'https://faucet.celo.org'
          );
        }
      }

      // Show approval message - user will see transaction in their wallet
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedToken == 'cUSD' 
              ? '📱 Opening wallet... You\'ll need to approve 2 transactions (approve + transfer)'
              : '📱 Opening wallet for approval...'
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      
      String txHash;

      // 🚀 REAL BLOCKCHAIN TRANSACTION via WalletConnect
      // User will see transaction details in their wallet app (Valora/MetaMask)
      // and must approve before transaction is signed
      if (_selectedToken == 'CELO') {
        // Pay with CELO - single transaction
        txHash = await _contractService.payWithCELO(
          merchantAddress: widget.merchantAddress,
          amount: amount,
          note: 'Payment to ${widget.merchantName}',
        );
      } else if (_selectedToken == 'cUSD') {
        // Pay with cUSD - requires TWO approvals: approve + transfer
        txHash = await _contractService.payWithCUSD(
          merchantAddress: widget.merchantAddress,
          amount: amount,
          note: 'Payment to ${widget.merchantName}',
        );
      } else {
        throw Exception('cEUR payments not yet supported');
      }

      print('✅ Payment successful! TxHash: $txHash');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Navigate to success screen with REAL transaction hash
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            amount: amount,
            token: _selectedToken,
            merchantName: widget.merchantName,
            txHash: txHash,
          ),
        ),
      );
    } on UserRejectedError {
      // User rejected transaction in their wallet
      print('❌ Payment rejected by user');
      
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Transaction rejected by user'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Payment failed: $e');
      
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Payment failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _web3Service.dispose();
    _contractService.dispose();
    super.dispose();
  }
}
