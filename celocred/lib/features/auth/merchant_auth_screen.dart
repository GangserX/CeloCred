import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/contract_service.dart';
import '../../core/services/appkit_service.dart';
import '../merchant/merchant_dashboard_screen.dart';

/// Merchant Authentication Screen
class MerchantAuthScreen extends StatefulWidget {
  final String? walletAddress;
  
  const MerchantAuthScreen({
    super.key,
    this.walletAddress,
  });

  @override
  State<MerchantAuthScreen> createState() => _MerchantAuthScreenState();
}

class _MerchantAuthScreenState extends State<MerchantAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _storage = StorageService();
  
  String _selectedCategory = 'Food & Beverage';
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Beverage',
    'Retail',
    'Services',
    'Agriculture',
    'Fashion',
    'Technology',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Registration'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.store,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Register Your Business',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Start accepting payments and build your credit score',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Show wallet address
              if (widget.walletAddress != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 16, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            'Wallet Connected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.walletAddress!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (widget.walletAddress != null)
                const SizedBox(height: 16),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Business Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register & Continue',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  // TODO: Implement login logic
                  _navigateToDashboard();
                },
                child: const Text('Already registered? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if wallet is connected via WalletConnect
      if (!AppKitService.instance.isConnected) {
        throw Exception('No wallet connected. Please connect your wallet first.');
      }

      // Show approval message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Opening wallet for approval...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 🚀 REAL BLOCKCHAIN CALL - Register merchant on Celo via WalletConnect
      // User will see transaction details in their wallet app (Valora/MetaMask)
      // and must approve before transaction is signed
      final contractService = ContractService();
      final txHash = await contractService.registerMerchant(
        businessName: _businessNameController.text,
        category: _selectedCategory,
        location: _locationController.text,
      );

      print('✅ Merchant registered on blockchain! TxHash: $txHash');
      
      // Save merchant info locally
      final walletAddress = await _storage.getWalletAddress();
      if (walletAddress != null) {
        await _storage.saveMerchantId(walletAddress);
      }
      await _storage.saveUserType('merchant');
      await _storage.setLoggedIn(true);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Registered on blockchain!\nTx: ${txHash.substring(0, 10)}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      _navigateToDashboard();
    } on UserRejectedError {
      // User rejected transaction in their wallet
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Transaction rejected by user'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantDashboardScreen(
          businessName: _businessNameController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
