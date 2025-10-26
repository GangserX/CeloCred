import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/contract_service.dart';
import '../../core/services/appkit_service.dart';
import '../../core/constants/celo_config.dart';
import '../../core/models/merchant_profile.dart';
import '../merchant/merchant_dashboard_screen.dart';

/// Merchant Onboarding Flow - Multi-step registration
class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({super.key});

  @override
  State<MerchantOnboardingScreen> createState() => _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Form controllers - Step 1: Business Info
  final _businessNameController = TextEditingController();
  final _businessCategoryController = TextEditingController();
  final _businessDescriptionController = TextEditingController();

  // Form controllers - Step 2: Location & Contact
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Business categories
  final List<String> _categories = [
    'Retail Store',
    'Restaurant & Food',
    'Services',
    'Technology',
    'Agriculture',
    'Manufacturing',
    'Healthcare',
    'Education',
    'Transportation',
    'Other',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessCategoryController.dispose();
    _businessDescriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Merchant'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep > 0 
              ? () => _previousStep() 
              : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Page View with steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1BusinessInfo(),
                _buildStep2LocationContact(),
                _buildStep3Review(),
              ],
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildProgressStep(1, 'Business Info', _currentStep >= 0),
          _buildProgressLine(_currentStep >= 1),
          _buildProgressStep(2, 'Contact', _currentStep >= 1),
          _buildProgressLine(_currentStep >= 2),
          _buildProgressStep(3, 'Review', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.green : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  // STEP 1: Business Information
  Widget _buildStep1BusinessInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.store,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Tell us about your business',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This information will be visible to customers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),

            // Business Name
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name *',
                hintText: 'e.g., John\'s Grocery Store',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your business name';
                }
                if (value.trim().length < 3) {
                  return 'Business name must be at least 3 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Business Category
            DropdownButtonFormField<String>(
              value: _businessCategoryController.text.isEmpty 
                  ? null 
                  : _businessCategoryController.text,
              decoration: InputDecoration(
                labelText: 'Business Category *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _businessCategoryController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a business category';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Business Description
            TextFormField(
              controller: _businessDescriptionController,
              decoration: InputDecoration(
                labelText: 'Business Description *',
                hintText: 'Describe what your business does...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 4,
              maxLength: 300,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your business';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A good description helps customers understand your business better',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
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

  // STEP 2: Location & Contact
  Widget _buildStep2LocationContact() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.contact_phone,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'How can customers reach you?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),

            // Business Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Business Location *',
                hintText: 'e.g., Nairobi, Kenya',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your business location';
                }
                if (value.trim().length < 3) {
                  return 'Location must be at least 3 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: '+254 700 000 000',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                // Basic phone validation
                final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]+$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email Address
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address *',
                hintText: 'business@example.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                // Email validation
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              textCapitalization: TextCapitalization.none,
            ),

            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Privacy Notice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Your contact information is stored securely in Firebase\n'
                    '• Phone and email are visible to customers making payments\n'
                    '• You can update this information anytime from your dashboard',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Review & Submit
  Widget _buildStep3Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Review Your Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please review your details before submitting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),

            // Business Info Card
            _buildReviewCard(
              title: 'Business Information',
              icon: Icons.store,
              children: [
                _buildReviewItem('Business Name', _businessNameController.text),
                _buildReviewItem('Category', _businessCategoryController.text),
                _buildReviewItem('Description', _businessDescriptionController.text),
              ],
            ),

            const SizedBox(height: 16),

            // Contact Info Card
            _buildReviewCard(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                _buildReviewItem('Location', _locationController.text),
                _buildReviewItem('Phone', _phoneController.text),
                _buildReviewItem('Email', _emailController.text),
              ],
            ),

            const SizedBox(height: 16),

            // Wallet Address Card
            Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return _buildReviewCard(
                  title: 'Blockchain Identity',
                  icon: Icons.account_balance_wallet,
                  children: [
                    _buildReviewItem(
                      'Wallet Address',
                      walletProvider.walletAddress ?? 'Not connected',
                    ),
                    _buildReviewItem('Network', 'Celo Alfajores Testnet'),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Terms & Conditions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'By registering, you agree to:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Accept payments in cUSD and CELO tokens\n'
                    '• Provide accurate business information\n'
                    '• Maintain good standing with customers\n'
                    '• Follow platform terms and conditions',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Register Business' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() async {
    // Validate current step
    bool isValid = false;
    
    switch (_currentStep) {
      case 0:
        isValid = _step1FormKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _step2FormKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _step3FormKey.currentState?.validate() ?? false;
        if (isValid) {
          await _submitRegistration();
          return;
        }
        break;
    }

    if (isValid && _currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final walletAddress = walletProvider.walletAddress;

      if (walletAddress == null) {
        throw Exception('Wallet not connected');
      }

      // Ensure we're on Sepolia testnet
      print('🔄 Checking current chain...');
      final currentChainId = await AppKitService.instance.getCurrentChainId();
      if (currentChainId != CeloConfig.celoTestnetChainId) {
        print('⚠️ Wrong chain detected. Switching to Sepolia...');
        final switched = await AppKitService.instance.switchChain(
          CeloConfig.celoTestnetChainId,
        );
        if (!switched) {
          throw Exception('Failed to switch to Sepolia testnet');
        }
        print('✅ Switched to Sepolia testnet');
      }

      // Create merchant profile
      final merchantProfile = MerchantProfile(
        walletAddress: walletAddress,
        businessName: _businessNameController.text.trim(),
        businessCategory: _businessCategoryController.text,
        businessDescription: _businessDescriptionController.text.trim(),
        location: _locationController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().toLowerCase(),
        kycStatus: 'pending',
        registeredAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isActive: true,
      );

      // Step 1: Register on blockchain (smart contract)
      print('🔗 Registering merchant on blockchain...');
      final contractService = ContractService();
      final txHash = await contractService.registerMerchant(
        businessName: merchantProfile.businessName,
        category: merchantProfile.businessCategory,
        location: merchantProfile.location,
      );
      print('✅ Blockchain registration successful! TxHash: $txHash');

      // Step 2: Save additional details to Firebase
      print('🔥 Saving merchant details to Firebase...');
      await FirebaseService.instance.registerMerchant(merchantProfile);
      print('✅ Firebase registration successful!');

      // Refresh merchant status in provider
      await walletProvider.refreshMerchantStatus();

      if (!mounted) return;

      // Show success and navigate to dashboard
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Registration Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your merchant account has been created successfully!',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s Next?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Start accepting payments\n'
                      '• View your dashboard\n'
                      '• Build your credit score\n'
                      '• Access merchant loans',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MerchantDashboardScreen(
                      businessName: _businessNameController.text.trim(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _submitRegistration(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
