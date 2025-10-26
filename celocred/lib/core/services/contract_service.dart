import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'dart:typed_data';
import '../constants/celo_config.dart';
import 'appkit_service.dart';

/// Service for interacting with deployed CeloCred smart contracts
/// SECURE VERSION - Uses WalletConnect, NO private keys!
class ContractService {
  late Web3Client _client;
  late DeployedContract _merchantRegistry;
  late DeployedContract _paymentProcessor;
  late DeployedContract _loanEscrow;
  late DeployedContract _creditScoreOracle;
  final AppKitService _appKit = AppKitService.instance;

  ContractService() {
    _client = Web3Client(CeloConfig.rpcUrl, http.Client());
    _initializeContracts();
  }

  void _initializeContracts() {
    _merchantRegistry = DeployedContract(
      ContractAbi.fromJson(_merchantRegistryABI, 'MerchantRegistry'),
      EthereumAddress.fromHex(CeloConfig.merchantRegistryAddress),
    );

    _paymentProcessor = DeployedContract(
      ContractAbi.fromJson(_paymentProcessorABI, 'PaymentProcessor'),
      EthereumAddress.fromHex(CeloConfig.paymentProcessorAddress),
    );

    _loanEscrow = DeployedContract(
      ContractAbi.fromJson(_loanEscrowABI, 'LoanEscrow'),
      EthereumAddress.fromHex(CeloConfig.loanEscrowAddress),
    );

    _creditScoreOracle = DeployedContract(
      ContractAbi.fromJson(_creditScoreOracleABI, 'CreditScoreOracle'),
      EthereumAddress.fromHex(CeloConfig.creditScoreOracleAddress),
    );
  }

  // Helper to convert function call to hex data
  String _encodeFunction(ContractFunction function, List<dynamic> params) {
    final encoded = function.encodeCall(params);
    return '0x${encoded.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  // Helper to convert hex string to Uint8List (for bytes32)
  Uint8List hexToBytes(String hexString) {
    // Remove 0x prefix if present
    final hex = hexString.startsWith('0x') ? hexString.substring(2) : hexString;
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  // ==================== MERCHANT REGISTRY ====================

  /// Register a merchant on-chain (SECURE - user approves in wallet!)
  Future<String> registerMerchant({
    required String businessName,
    required String category,
    required String location,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      print('📝 Preparing merchant registration...');
      print('   Business: $businessName');
      print('   Category: $category');
      print('   Location: $location');

      final function = _merchantRegistry.function('registerMerchant');
      final data = _encodeFunction(function, [businessName, category, location]);

      // Send to wallet for approval (USER APPROVES IN VALORA/METAMASK!)
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.merchantRegistryAddress,
        value: BigInt.zero,
        data: data,
        gas: BigInt.from(300000),
      );

      print('✅ Merchant registered! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error registering merchant: $e');
      rethrow;
    }
  }

  /// Get merchant details from blockchain (read-only, no signature needed)
  Future<Map<String, dynamic>> getMerchant(String merchantAddress) async {
    try {
      final function = _merchantRegistry.function('getMerchant');
      final result = await _client.call(
        contract: _merchantRegistry,
        function: function,
        params: [EthereumAddress.fromHex(merchantAddress)],
      );

      return {
        'businessName': result[0] as String,
        'category': result[1] as String,
        'location': result[2] as String,
        'registrationDate': (result[3] as BigInt).toInt(),
        'isActive': result[4] as bool,
        'totalTransactions': (result[5] as BigInt).toInt(),
        'totalVolume': (result[6] as BigInt).toInt(),
      };
    } catch (e) {
      print('❌ Error getting merchant: $e');
      rethrow;
    }
  }

  /// Check if address is a registered merchant (read-only)
  Future<bool> isMerchant(String address) async {
    try {
      final function = _merchantRegistry.function('isMerchant');
      final result = await _client.call(
        contract: _merchantRegistry,
        function: function,
        params: [EthereumAddress.fromHex(address)],
      );
      return result[0] as bool;
    } catch (e) {
      print('❌ Error checking merchant status: $e');
      rethrow;
    }
  }

  // ==================== PAYMENT PROCESSOR ====================

  /// Process payment in CELO (SECURE - user approves in wallet!)
  Future<String> payWithCELO({
    required String merchantAddress,
    required double amount,
    required String note,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      final amountInWei = BigInt.from((amount * 1e18).toInt());

      print('💰 Preparing CELO payment on Sepolia:');
      print('   Amount: $amount CELO');
      print('   Amount in Wei: $amountInWei');
      print('   Merchant: $merchantAddress');
      print('   Note: $note');

      final function = _paymentProcessor.function('payWithCELO');
      final data = _encodeFunction(function, [
        EthereumAddress.fromHex(merchantAddress),
        note,
      ]);

      // Send to wallet for approval (WALLET SHOWS: "Send X CELO to merchant?")
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.paymentProcessorAddress,
        value: amountInWei, // CELO amount sent as value
        data: data,
        gas: BigInt.from(300000),
      );

      print('✅ Payment successful! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error processing CELO payment: $e');
      rethrow;
    }
  }

  /// Process payment in cUSD (SECURE - user approves TWICE!)
  /// Step 1: Approve PaymentProcessor to spend cUSD
  /// Step 2: Execute payment
  Future<String> payWithCUSD({
    required String merchantAddress,
    required double amount,
    required String note,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      final amountInWei = BigInt.from((amount * 1e18).toInt());

      print('💰 Processing cUSD payment on Sepolia (2 transactions):');
      print('   Amount: $amount cUSD');
      print('   Merchant: $merchantAddress');

      // Step 1: Approve PaymentProcessor to spend cUSD
      print('   Step 1: Requesting cUSD spending approval...');
      
      final cUSDContract = DeployedContract(
        ContractAbi.fromJson(
          '[{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}]',
          'cUSD',
        ),
        EthereumAddress.fromHex(CeloConfig.cUSDAddress),
      );

      final approveFunction = cUSDContract.function('approve');
      final approveData = _encodeFunction(approveFunction, [
        EthereumAddress.fromHex(CeloConfig.paymentProcessorAddress),
        amountInWei,
      ]);

      // First approval (WALLET SHOWS: "Approve PaymentProcessor to spend cUSD?")
      await _appKit.sendTransaction(
        to: CeloConfig.cUSDAddress,
        value: BigInt.zero,
        data: approveData,
        gas: BigInt.from(100000),
      );

      print('   ✅ Approval successful!');
      print('   Step 2: Executing payment...');

      // Step 2: Execute payment
      final function = _paymentProcessor.function('payWithCUSD');
      final data = _encodeFunction(function, [
        EthereumAddress.fromHex(merchantAddress),
        amountInWei,
        note,
      ]);

      // Second transaction (WALLET SHOWS: "Send X cUSD to merchant?")
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.paymentProcessorAddress,
        value: BigInt.zero,
        data: data,
        gas: BigInt.from(300000),
      );

      print('✅ Payment successful! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error processing cUSD payment: $e');
      rethrow;
    }
  }

  // ==================== LOAN ESCROW ====================

  /// Request a loan on-chain (SECURE - user approves in wallet!)
  Future<String> requestLoan({
    required double amount,
    required int interestRate, // basis points (e.g., 500 = 5%)
    required int durationDays,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      final amountInWei = BigInt.from((amount * 1e18).toInt());

      print('📋 Preparing loan request on Sepolia:');
      print('   Amount: $amount cUSD');
      print('   Interest Rate: ${interestRate / 100}%');
      print('   Duration: $durationDays days');

      final function = _loanEscrow.function('requestLoan');
      final data = _encodeFunction(function, [
        amountInWei,
        BigInt.from(interestRate),
        BigInt.from(durationDays),
      ]);

      // Send to wallet for approval (WALLET SHOWS: "Request loan?")
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.loanEscrowAddress,
        value: BigInt.zero,
        data: data,
        gas: BigInt.from(300000),
      );

      print('✅ Loan requested! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error requesting loan: $e');
      rethrow;
    }
  }

  /// Request a loan WITH NFT collateral (SECURE - user approves in wallet!)
  Future<String> requestLoanWithCollateral({
    required double amount,
    required int interestRate, // basis points (e.g., 500 = 5%)
    required int durationDays,
    required String nftContractAddress,
    required int nftTokenId,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      final amountInWei = BigInt.from((amount * 1e18).toInt());

      print('📋 Preparing collateralized loan request on Sepolia:');
      print('   Amount: $amount cUSD');
      print('   Interest Rate: ${interestRate / 100}%');
      print('   Duration: $durationDays days');
      print('   NFT: $nftContractAddress #$nftTokenId');

      final function = _loanEscrow.function('requestLoanWithCollateral');
      final data = _encodeFunction(function, [
        amountInWei,
        BigInt.from(interestRate),
        BigInt.from(durationDays),
        EthereumAddress.fromHex(nftContractAddress),
        BigInt.from(nftTokenId),
      ]);

      // Send to wallet for approval (WALLET SHOWS: "Request loan with NFT collateral?")
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.loanEscrowAddress,
        value: BigInt.zero,
        data: data,
        gas: BigInt.from(400000), // Higher gas for NFT transfer
      );

      print('✅ Collateralized loan requested! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error requesting collateralized loan: $e');
      rethrow;
    }
  }

  /// Fund a loan (become the lender)
  Future<String> fundLoan({
    required String loanId,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      print('💰 Funding loan: $loanId');

      final function = _loanEscrow.function('fundLoan');
      
      // Convert hex string to bytes32
      final loanIdBytes = hexToBytes(loanId);
      
      final data = _encodeFunction(function, [loanIdBytes]);

      // Note: Requires prior cUSD approval!
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.loanEscrowAddress,
        value: BigInt.zero,
        data: data,
        gas: BigInt.from(300000),
      );

      print('✅ Loan funded! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error funding loan: $e');
      rethrow;
    }
  }

  /// Repay a loan
  Future<String> repayLoan({
    required String loanId,
  }) async {
    try {
      if (!_appKit.isConnected) {
        throw Exception('Please connect your wallet first');
      }

      print('💸 Repaying loan: $loanId');

      final function = _loanEscrow.function('repayLoan');
      final loanIdBytes = hexToBytes(loanId);
      final data = _encodeFunction(function, [loanIdBytes]);

      // Note: Requires prior cUSD approval for repayment amount!
      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.loanEscrowAddress,
        value: BigInt.zero,
        data: data,
        gas: BigInt.from(300000),
      );

      print('✅ Loan repaid! TxHash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Error repaying loan: $e');
      rethrow;
    }
  }

  /// Approve cUSD for loan operations (funding or repayment)
  Future<String> approveCUSDForLoan(double amount) async {
    try {
      final amountInWei = BigInt.from((amount * 1e18).toInt());
      
      print('🔓 Approving $amount cUSD for loan operations...');

      final cUSDContract = DeployedContract(
        ContractAbi.fromJson(
          '[{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}]',
          'cUSD',
        ),
        EthereumAddress.fromHex(CeloConfig.cUSDAddress),
      );

      final approveFunction = cUSDContract.function('approve');
      final approveData = _encodeFunction(approveFunction, [
        EthereumAddress.fromHex(CeloConfig.loanEscrowAddress),
        amountInWei,
      ]);

      final txHash = await _appKit.sendTransaction(
        to: CeloConfig.cUSDAddress,
        value: BigInt.zero,
        data: approveData,
        gas: BigInt.from(100000),
      );

      print('✅ cUSD approved for loan operations');
      return txHash;
    } catch (e) {
      print('❌ Error approving cUSD: $e');
      rethrow;
    }
  }

  /// Get all pending loans from blockchain (read-only)
  Future<List<String>> getPendingLoans() async {
    try {
      final function = _loanEscrow.function('getPendingLoans');
      final result = await _client.call(
        contract: _loanEscrow,
        function: function,
        params: [],
      );

      final loanIds = (result[0] as List).map((id) {
        final bytes = id as List<int>;
        return '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      }).toList();

      print('📋 Found ${loanIds.length} pending loans');
      return loanIds;
    } catch (e) {
      print('❌ Error getting pending loans: $e');
      rethrow;
    }
  }

  // ==================== CREDIT SCORE ORACLE ====================

  /// Get credit score from oracle (read-only)
  Future<Map<String, dynamic>> getCreditScore(String userAddress) async {
    try {
      final function = _creditScoreOracle.function('getCreditScore');
      
      final result = await _client.call(
        contract: _creditScoreOracle,
        function: function,
        params: [EthereumAddress.fromHex(userAddress)],
      );

      return {
        'score': (result[0] as BigInt).toInt(),
        'lastUpdated': (result[1] as BigInt).toInt(),
        'exists': result[2] as bool,
      };
    } catch (e) {
      print('❌ Error getting credit score: $e');
      rethrow;
    }
  }

  // ==================== ABI DEFINITIONS ====================

  static const String _merchantRegistryABI = '''
  [
    {
      "inputs": [
        {"name": "businessName", "type": "string"},
        {"name": "category", "type": "string"},
        {"name": "location", "type": "string"}
      ],
      "name": "registerMerchant",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "merchantAddress", "type": "address"}],
      "name": "getMerchant",
      "outputs": [
        {"name": "businessName", "type": "string"},
        {"name": "category", "type": "string"},
        {"name": "location", "type": "string"},
        {"name": "registrationDate", "type": "uint256"},
        {"name": "isActive", "type": "bool"},
        {"name": "totalTransactions", "type": "uint256"},
        {"name": "totalVolume", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name": "_address", "type": "address"}],
      "name": "isMerchant",
      "outputs": [{"name": "", "type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  static const String _paymentProcessorABI = '''
  [
    {
      "inputs": [
        {"name": "_merchant", "type": "address"},
        {"name": "_note", "type": "string"}
      ],
      "name": "payWithCELO",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "_merchant", "type": "address"},
        {"name": "_amount", "type": "uint256"},
        {"name": "_note", "type": "string"}
      ],
      "name": "payWithCUSD",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]
  ''';

  static const String _loanEscrowABI = '''
  [
    {
      "inputs": [
        {"name": "_amount", "type": "uint256"},
        {"name": "_interestRate", "type": "uint256"},
        {"name": "_durationDays", "type": "uint256"}
      ],
      "name": "requestLoan",
      "outputs": [{"name": "", "type": "bytes32"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "_amount", "type": "uint256"},
        {"name": "_interestRate", "type": "uint256"},
        {"name": "_durationDays", "type": "uint256"},
        {"name": "_nftContract", "type": "address"},
        {"name": "_nftTokenId", "type": "uint256"}
      ],
      "name": "requestLoanWithCollateral",
      "outputs": [{"name": "", "type": "bytes32"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "_loanId", "type": "bytes32"}],
      "name": "fundLoan",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "_loanId", "type": "bytes32"}],
      "name": "repayLoan",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "_loanId", "type": "bytes32"}],
      "name": "getLoan",
      "outputs": [
        {"name": "borrower", "type": "address"},
        {"name": "lender", "type": "address"},
        {"name": "amount", "type": "uint256"},
        {"name": "interestRate", "type": "uint256"},
        {"name": "duration", "type": "uint256"},
        {"name": "dueDate", "type": "uint256"},
        {"name": "status", "type": "uint8"},
        {"name": "hasCollateral", "type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getPendingLoans",
      "outputs": [{"name": "", "type": "bytes32[]"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  static const String _creditScoreOracleABI = '''
  [
    {
      "inputs": [{"name": "_user", "type": "address"}],
      "name": "getCreditScore",
      "outputs": [
        {"name": "score", "type": "uint256"},
        {"name": "lastUpdated", "type": "uint256"},
        {"name": "exists", "type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  void dispose() {
    _client.dispose();
  }
}
