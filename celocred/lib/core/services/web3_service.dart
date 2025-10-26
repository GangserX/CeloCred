import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' hide Wallet;
import '../constants/celo_config.dart';
import '../models/wallet_model.dart';
import 'package:web3dart/crypto.dart';

/// Web3 service for blockchain interactions
class Web3Service {
  late Web3Client _client;
  late EthereumAddress _cUSDAddress;
  late EthereumAddress _cEURAddress;

  Web3Service() {
    _client = Web3Client(CeloConfig.rpcUrl, http.Client());
    _cUSDAddress = EthereumAddress.fromHex(CeloConfig.cUSDAddress);
    _cEURAddress = EthereumAddress.fromHex(CeloConfig.cEURAddress);
  }

  /// Generate new wallet (does NOT auto-save to storage)
  Future<Wallet> generateWallet() async {
    final random = Random.secure();
    final credentials = EthPrivateKey.createRandom(random);
    final address = await credentials.extractAddress();
    
    // Note: In production, generate actual mnemonic
    final privateKey = credentials.privateKey;
    final privateKeyHex = '0x${privateKey.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';

    final wallet = Wallet(
      address: address.hexEip55,
      privateKey: privateKeyHex,
      mnemonic: null, // TODO: Generate actual mnemonic
    );

    // DON'T auto-save - let the UI handle this explicitly
    // await _storage.saveWalletAddress(wallet.address);
    // await _storage.savePrivateKey(privateKeyHex);

    return wallet;
  }

  /// Import wallet from private key (does NOT auto-save to storage)
  Future<Wallet> importWalletFromPrivateKey(String privateKeyHex) async {
    // Remove 0x prefix if present
    if (privateKeyHex.startsWith('0x')) {
      privateKeyHex = privateKeyHex.substring(2);
    }

    final privateKeyBytes = hexToBytes(privateKeyHex);
    final credentials = EthPrivateKey(privateKeyBytes);
    final address = await credentials.extractAddress();

    final wallet = Wallet(
      address: address.hexEip55,
      privateKey: '0x$privateKeyHex',
    );

    // DON'T auto-save - let the UI handle this explicitly
    // await _storage.saveWalletAddress(wallet.address);
    // await _storage.savePrivateKey('0x$privateKeyHex');

    return wallet;
  }

  /// Get CELO balance
  Future<double> getCeloBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      final balance = await _client.getBalance(ethAddress);
      return balance.getValueInUnit(EtherUnit.ether).toDouble();
    } catch (e) {
      print('Error getting CELO balance: $e');
      return 0.0;
    }
  }

  /// Get cUSD balance
  Future<double> getCUSDBalance(String address) async {
    return await _getTokenBalance(address, _cUSDAddress);
  }

  /// Get cEUR balance
  Future<double> getCEURBalance(String address) async {
    return await _getTokenBalance(address, _cEURAddress);
  }

  /// Get token balance (generic ERC20)
  Future<double> _getTokenBalance(
      String walletAddress, EthereumAddress tokenAddress) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20ABI, 'ERC20'),
        tokenAddress,
      );

      final balanceFunction = contract.function('balanceOf');
      final result = await _client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      final balance = result[0] as BigInt;
      return balance / BigInt.from(10).pow(18);
    } catch (e) {
      print('Error getting token balance: $e');
      return 0.0;
    }
  }

  /// Send CELO
  Future<String> sendCelo({
    required String privateKeyHex,
    required String toAddress,
    required double amount,
  }) async {
    try {
      if (privateKeyHex.startsWith('0x')) {
        privateKeyHex = privateKeyHex.substring(2);
      }

      final credentials = EthPrivateKey(hexToBytes(privateKeyHex));
      final recipient = EthereumAddress.fromHex(toAddress);
      final amountInWei = EtherAmount.fromUnitAndValue(
        EtherUnit.ether,
        (amount * 1e18).toInt(),
      );

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction(
          to: recipient,
          value: amountInWei,
          maxGas: CeloConfig.defaultGasLimit,
        ),
        chainId: CeloConfig.chainId,
      );

      return txHash;
    } catch (e) {
      print('Error sending CELO: $e');
      rethrow;
    }
  }

  /// Send cUSD or cEUR
  Future<String> sendToken({
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    required String tokenType, // 'cUSD' or 'cEUR'
  }) async {
    try {
      if (privateKeyHex.startsWith('0x')) {
        privateKeyHex = privateKeyHex.substring(2);
      }

      final credentials = EthPrivateKey(hexToBytes(privateKeyHex));
      final recipient = EthereumAddress.fromHex(toAddress);
      final tokenAddress =
          tokenType == 'cUSD' ? _cUSDAddress : _cEURAddress;

      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20ABI, 'ERC20'),
        tokenAddress,
      );

      final transferFunction = contract.function('transfer');
      final amountInWei = BigInt.from((amount * 1e18).toInt());

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: transferFunction,
          parameters: [recipient, amountInWei],
          maxGas: CeloConfig.defaultGasLimit,
        ),
        chainId: CeloConfig.chainId,
      );

      return txHash;
    } catch (e) {
      print('Error sending token: $e');
      rethrow;
    }
  }

  /// Get transaction receipt
  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    try {
      return await _client.getTransactionReceipt(txHash);
    } catch (e) {
      print('Error getting transaction receipt: $e');
      return null;
    }
  }

  /// Dispose client
  void dispose() {
    _client.dispose();
  }

  // ERC20 ABI (simplified)
  static const String _erc20ABI = '''
  [
    {
      "constant": true,
      "inputs": [{"name": "_owner", "type": "address"}],
      "name": "balanceOf",
      "outputs": [{"name": "balance", "type": "uint256"}],
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {"name": "_to", "type": "address"},
        {"name": "_value", "type": "uint256"}
      ],
      "name": "transfer",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    }
  ]
  ''';
}
