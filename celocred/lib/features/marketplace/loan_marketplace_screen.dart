import 'package:flutter/material.dart';
import '../../core/services/contract_service.dart';

/// Loan Marketplace Screen
class LoanMarketplaceScreen extends StatefulWidget {
  const LoanMarketplaceScreen({super.key});

  @override
  State<LoanMarketplaceScreen> createState() => _LoanMarketplaceScreenState();
}

class _LoanMarketplaceScreenState extends State<LoanMarketplaceScreen> {
  final _contractService = ContractService();
  
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<String> _loanIds = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  /// 🚀 REAL BLOCKCHAIN - Load pending loans from smart contract
  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📋 Fetching pending loans from blockchain...');
      
      // Get all pending loan IDs from blockchain
      final loanIds = await _contractService.getPendingLoans();
      
      print('✅ Found ${loanIds.length} pending loans');
      
      setState(() {
        _loanIds = loanIds;
      });
    } catch (e) {
      print('❌ Error loading loans: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Marketplace'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('🟢 Excellent'),
                        _buildFilterChip('🟡 Fair'),
                        _buildFilterChip('🔐 With Collateral'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    // TODO: Implement sorting
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sorting by $value')),
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Recently Listed',
                      child: Text('Recently Listed'),
                    ),
                    const PopupMenuItem(
                      value: 'Highest Interest',
                      child: Text('Highest Interest'),
                    ),
                    const PopupMenuItem(
                      value: 'Lowest Risk',
                      child: Text('Lowest Risk'),
                    ),
                    const PopupMenuItem(
                      value: 'Almost Funded',
                      child: Text('Almost Funded'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Loan List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading loans from blockchain...'),
                      ],
                    ),
                  )
                : _loanIds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No pending loans found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for loan opportunities',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadLoans,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLoans,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _loanIds.length,
                          itemBuilder: (context, index) {
                            return _buildLoanCard(_loanIds[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = label);
        },
        selectedColor: Colors.orange.shade100,
      ),
    );
  }

  /// Build loan card from blockchain loan ID
  Widget _buildLoanCard(String loanId) {
    // TODO: Fetch full loan details from blockchain
    // For now, showing loan ID with mock display
    // In production, call contractService.getLoanDetails(loanId)
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan ID
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loan Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ID: ${loanId.substring(0, 10)}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Loan Details Placeholder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Full loan details coming soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The LoanEscrow contract needs a getLoanDetails function',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to loan detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loan ID: $loanId'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }





  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Credit Score Range'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Excellent (70-100)'),
                    selected: false,
                    onSelected: (value) {},
                  ),
                  FilterChip(
                    label: const Text('Fair (50-69)'),
                    selected: false,
                    onSelected: (value) {},
                  ),
                  FilterChip(
                    label: const Text('Growing (0-49)'),
                    selected: false,
                    onSelected: (value) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _contractService.dispose();
    super.dispose();
  }
}
