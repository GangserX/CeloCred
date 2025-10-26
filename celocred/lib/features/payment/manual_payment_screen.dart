import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'payment_confirmation_screen.dart';
import '../../core/services/contract_service.dart';

/// Manual Payment Screen - Enter merchant address manually for testing
class ManualPaymentScreen extends StatefulWidget {
  const ManualPaymentScreen({super.key});

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _merchantNameController = TextEditingController();
  final _contractService = ContractService();
  
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Payment'),
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
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Pay to Wallet Address',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter merchant wallet address manually',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Merchant Address Input
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Merchant Wallet Address',
                  hintText: '0x...',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: _pasteAddress,
                    tooltip: 'Paste from clipboard',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter merchant address';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Invalid Celo address format';
                  }
                  return null;
                },
                onChanged: (_) {
                  setState(() {
                    _isVerified = false;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Merchant Name Input (optional)
              TextFormField(
                controller: _merchantNameController,
                decoration: InputDecoration(
                  labelText: 'Merchant Name (optional)',
                  hintText: 'e.g., John\'s Store',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Verify Button
              ElevatedButton.icon(
                onPressed: _isVerifying ? null : _verifyMerchant,
                icon: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(_isVerified ? Icons.check_circle : Icons.search),
                label: Text(_isVerified ? 'Verified ✓' : 'Verify Merchant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.green : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Continue Button
              ElevatedButton(
                onPressed: _isVerified ? _proceedToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Help Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How to get merchant address:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem('1. Ask merchant for their wallet address'),
                    _buildHelpItem('2. Address starts with "0x" and has 42 characters'),
                    _buildHelpItem('3. Click Verify to check if merchant is registered'),
                    _buildHelpItem('4. Or scan their QR code instead'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Example addresses for testing
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Testing:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ IMPORTANT: You CANNOT send payment to your own address!\n\nUse this test merchant address:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: SelectableText(
                              '0x5850978373D187bd35210828027739b336546057',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(
                                  text: '0x5850978373D187bd35210828027739b336546057',
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Test address copied!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
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
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _addressController.text = data!.text!;
      setState(() {
        _isVerified = false;
      });
    }
  }

  Future<void> _verifyMerchant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final address = _addressController.text.trim();
      
      // 🚀 REAL BLOCKCHAIN CALL - Check if registered merchant
      final isMerchant = await _contractService.isMerchant(address);
      
      if (isMerchant) {
        // Fetch merchant details
        final merchantData = await _contractService.getMerchant(address);
        _merchantNameController.text = merchantData['businessName'] ?? 'Unknown';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Verified merchant: ${merchantData['businessName']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Address not a registered merchant (you can still send payment)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      setState(() {
        _isVerified = true;
      });
    } catch (e) {
      print('Error verifying merchant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _proceedToPayment() {
    final merchantName = _merchantNameController.text.isNotEmpty
        ? _merchantNameController.text
        : 'Wallet ${_addressController.text.substring(0, 6)}...';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          merchantName: merchantName,
          merchantAddress: _addressController.text.trim(),
          merchantCategory: 'Direct Transfer',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _merchantNameController.dispose();
    _contractService.dispose();
    super.dispose();
  }
}
