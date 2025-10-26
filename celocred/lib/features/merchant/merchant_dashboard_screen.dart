import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/models/merchant_profile.dart';
import '../../core/models/loan_model.dart';
import '../credit_score/credit_score_detail_screen.dart';
import '../loan/loan_request_screen.dart';
import '../loan/loan_repayment_screen.dart';

/// Merchant Dashboard Screen - Firebase Integrated
class MerchantDashboardScreen extends StatefulWidget {
  final String? businessName;

  const MerchantDashboardScreen({
    super.key,
    this.businessName,
  });

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Firebase data
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  MerchantProfile? _merchantProfile;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentTransactions = [];
  int? _creditScore;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final walletAddress = walletProvider.walletAddress;

      if (walletAddress == null) {
        throw Exception('Wallet not connected');
      }

      // Fetch merchant profile from Firebase
      final profile = await FirebaseService.instance.getMerchantProfile(walletAddress);
      if (profile == null) {
        throw Exception('Merchant profile not found');
      }

      // Fetch statistics from Firebase
      final stats = await FirebaseService.instance.getMerchantStats(walletAddress);

      // Fetch recent transactions (last 10)
      final transactions = await FirebaseService.instance.getMerchantTransactions(
        walletAddress,
        limit: 10,
      );

      // Fetch credit score
      final creditScoreData = await FirebaseService.instance.getCreditScore(walletAddress);
      final score = (creditScoreData?['score'] as num?)?.toInt();

      setState(() {
        _merchantProfile = profile;
        _stats = stats;
        _recentTransactions = transactions;
        _creditScore = score;
        _isLoading = false;
      });
      
      print('✅ Dashboard loaded: ${profile.businessName}');
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.businessName ?? 'Merchant Dashboard'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Loading dashboard...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.businessName ?? 'Merchant Dashboard'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Load Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_merchantProfile?.businessName ?? widget.businessName ?? 'Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'QR'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
            Tab(icon: Icon(Icons.account_balance), text: 'Loans'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Section with Credit Score
          _buildTopSection(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQRTab(),
                _buildTransactionsTab(),
                _buildLoansTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    final creditScore = _creditScore ?? 0;
    final scoreColor = creditScore >= 70
        ? Colors.green
        : creditScore >= 50
            ? Colors.orange
            : Colors.red;

    final totalSales = ((_stats?['totalRevenue'] ?? 0.0) as num).toDouble();
    final totalTransactions = ((_stats?['totalTransactions'] ?? 0) as num).toInt();
    final averageTransaction = ((_stats?['averageTransaction'] ?? 0.0) as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Credit Score Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Credit Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$creditScore',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          creditScore >= 70 ? 'Excellent' : creditScore >= 50 ? 'Fair' : creditScore > 0 ? 'Growing' : 'No Score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreditScoreDetailScreen(
                        merchantId: '',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('View\nBreakdown'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Financial Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Sales', '$totalTransactions tx'),
              _buildStatItem('Total Revenue', '\$${_formatAmount(totalSales)} cUSD'),
              _buildStatItem('Avg Transaction', '\$${_formatAmount(averageTransaction)}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0.00';
    if (amount < 0.01) return amount.toStringAsFixed(4);
    return amount.toStringAsFixed(2);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildQRTab() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final walletAddress = walletProvider.walletAddress ?? '0x0000000000000000000000000000000000000000';
    final businessName = _merchantProfile?.businessName ?? widget.businessName ?? 'Merchant';
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Payment QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customers scan this to pay you',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: 'celocred:merchant:$businessName:$walletAddress',
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              businessName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: walletAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wallet address copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // Share QR (future implementation)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR share feature coming soon!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment transactions will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _recentTransactions[index];
          final amount = transaction['amount'] ?? 0;
          final currency = transaction['currency'] ?? 'cUSD';
          final customerAddress = transaction['customerAddress'] ?? 'Unknown';
          final timestamp = transaction['timestamp'];
          
          String timeAgo = 'Just now';
          String dateStr = '';
          
          if (timestamp != null) {
            final txDate = (timestamp as Timestamp).toDate();
            final difference = DateTime.now().difference(txDate);
            
            if (difference.inDays > 0) {
              timeAgo = '${difference.inDays}d ago';
            } else if (difference.inHours > 0) {
              timeAgo = '${difference.inHours}h ago';
            } else if (difference.inMinutes > 0) {
              timeAgo = '${difference.inMinutes}m ago';
            }
            
            // Format date
            dateStr = '${txDate.month}/${txDate.day}/${txDate.year}';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => _showTransactionDetails(transaction),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Transaction Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Received',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr.isNotEmpty ? dateStr : timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${customerAddress.substring(0, 6)}...${customerAddress.substring(customerAddress.length - 4)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${_formatAmount(amount.toDouble())}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt, color: Colors.green),
            SizedBox(width: 8),
            Text('Transaction Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '${_formatAmount((transaction['amount'] ?? 0).toDouble())} ${transaction['currency'] ?? 'cUSD'}'),
            const Divider(height: 16),
            _buildDetailRow('From', transaction['customerAddress'] ?? 'Unknown'),
            const Divider(height: 16),
            _buildDetailRow('Transaction Hash', transaction['txHash'] ?? 'N/A'),
            const Divider(height: 16),
            _buildDetailRow('Status', transaction['status'] ?? 'completed'),
            if (transaction['notes'] != null) ...[
              const Divider(height: 16),
              _buildDetailRow('Notes', transaction['notes']),
            ],
          ],
        ),
        actions: [
          if (transaction['txHash'] != null && transaction['txHash'].toString().isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: transaction['txHash']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction hash copied!')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Hash'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
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
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLoansTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoanRequestScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Request New Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Active Loans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Query active/funded loans for current user
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getActiveLoansStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading loans',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No active loans',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Request your first loan to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show list of active loans
                final loans = snapshot.data!.docs
                    .map((doc) => Loan.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return _buildLoanCard(loan);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Get stream of active loans for current merchant
  Stream<QuerySnapshot> _getActiveLoansStream() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final walletAddress = walletProvider.walletAddress;

    if (walletAddress == null) {
      return const Stream.empty();
    }

    // Query loans where:
    // - merchantWallet matches current user
    // - status is 'approved' or 'disbursed' (loans that can be repaid)
    return FirebaseFirestore.instance
        .collection('loans')
        .where('merchantWallet', isEqualTo: walletAddress)
        .where('status', whereIn: [
          LoanStatus.approved.name,
          LoanStatus.disbursed.name,
        ])
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  /// Build a card for each active loan
  Widget _buildLoanCard(Loan loan) {
    final canRepay = loan.status == LoanStatus.disbursed;
    final statusColor = loan.status == LoanStatus.disbursed ? Colors.green : Colors.orange;
    final statusIcon = loan.status == LoanStatus.disbursed ? Icons.check_circle : Icons.pending;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${loan.amount.toStringAsFixed(2)} cUSD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            loan.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canRepay)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanRepaymentScreen(loan: loan),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Repay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildLoanDetail(
                    'Interest Rate',
                    '${loan.interestRate.toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _buildLoanDetail(
                    'Term',
                    '${loan.termDays} days',
                  ),
                ),
                Expanded(
                  child: _buildLoanDetail(
                    'Total Repayment',
                    '\$${loan.totalRepaymentAmount.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            if (loan.dueDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: loan.isOverdue 
                      ? Colors.red.shade50 
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      loan.isOverdue ? Icons.warning : Icons.calendar_today,
                      size: 16,
                      color: loan.isOverdue ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loan.isOverdue
                          ? 'Overdue! Please repay immediately'
                          : 'Due: ${loan.dueDate!.day}/${loan.dueDate!.month}/${loan.dueDate!.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: loan.isOverdue 
                            ? Colors.red.shade900 
                            : Colors.blue.shade900,
                        fontWeight: loan.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (loan.hasCollateral) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Secured with NFT collateral',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildProfileTab() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final businessName = _merchantProfile?.businessName ?? widget.businessName ?? 'Merchant';
    final category = _merchantProfile?.businessCategory ?? 'Not specified';
    final location = _merchantProfile?.location ?? 'Not specified';
    final phone = _merchantProfile?.contactPhone ?? 'Not specified';
    final email = _merchantProfile?.contactEmail ?? 'Not specified';
    final walletAddress = walletProvider.walletAddress ?? '0x0000000000000000000000000000000000000000';
    final registeredDate = _merchantProfile?.registeredAt;
    
    String registeredStr = 'Unknown';
    if (registeredDate != null) {
      registeredStr = '${registeredDate.month}/${registeredDate.day}/${registeredDate.year}';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Logo or Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
            ),
            child: _merchantProfile?.logoUrl != null
                ? ClipOval(
                    child: Image.network(
                      _merchantProfile!.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.store, size: 50, color: Colors.green);
                      },
                    ),
                  )
                : const Icon(Icons.store, size: 50, color: Colors.green),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          businessName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          category,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        
        // KYC Status Badge
        const SizedBox(height: 16),
        Center(child: _buildKYCBadge()),
        
        const SizedBox(height: 32),
        
        // Profile Information
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text('Location'),
                subtitle: Text(location),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile editing coming soon!')),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Phone'),
                subtitle: Text(phone),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.green),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wallet, color: Colors.green),
                title: const Text('Wallet Address'),
                subtitle: Text(
                  '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: walletAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallet address copied!')),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text('Registered'),
                subtitle: Text(registeredStr),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Description
        if (_merchantProfile?.businessDescription != null && _merchantProfile!.businessDescription.isNotEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Business',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _merchantProfile!.businessDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Logout Button
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout and return to the home screen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Back to Home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildKYCBadge() {
    final status = _merchantProfile?.kycStatus ?? 'pending';
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'verified':
        badgeColor = Colors.green;
        badgeText = 'Verified';
        badgeIcon = Icons.verified;
        break;
      case 'rejected':
        badgeColor = Colors.red;
        badgeText = 'Rejected';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.orange;
        badgeText = 'Pending KYC';
        badgeIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 14,
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
