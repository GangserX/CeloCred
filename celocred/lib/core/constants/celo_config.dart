/// Celo Blockchain Configuration
class CeloConfig {
  // Network Selection
  static const bool useTestnet = true; // Set to false for mainnet

  // Chain IDs
  static const int celoMainnetChainId = 42220;
  static const int celoTestnetChainId = 11142220; // Celo Sepolia Testnet

  static int get chainId =>
      useTestnet ? celoTestnetChainId : celoMainnetChainId;

  // RPC Endpoints
  static const String celoMainnetRpc = 'https://forno.celo.org';
  static const String celoTestnetRpc = 'https://forno.celo-sepolia.celo-testnet.org';

  static String get rpcUrl => useTestnet ? celoTestnetRpc : celoMainnetRpc;

  // Token Addresses - Mainnet
  static const String celoMainnetAddress =
      '0x471EcE3750Da237f93B8E339c536989b8978a438';
  static const String cUSDMainnetAddress =
      '0x765DE816845861e75A25fCA122bb6898B8B1282a';
  static const String cEURMainnetAddress =
      '0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73';

  // Token Addresses - Sepolia Testnet
  static const String celoSepoliaAddress =
      '0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9';
  static const String cUSDSepoliaAddress =
      '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1';
  static const String cEURSepoliaAddress =
      '0x10c892A6EC43a53E45D0B916B4b7D383B1b78C0F';

  // Get current network addresses
  static String get celoAddress =>
      useTestnet ? celoSepoliaAddress : celoMainnetAddress;
  static String get cUSDAddress =>
      useTestnet ? cUSDSepoliaAddress : cUSDMainnetAddress;
  static String get cEURAddress =>
      useTestnet ? cEURSepoliaAddress : cEURMainnetAddress;

  // Gas Configuration
  static const int defaultGasLimit = 200000;
  static const String defaultGasPrice = '1000000000'; // 1 Gwei

  // Explorer URLs
  static const String celoMainnetExplorer = 'https://explorer.celo.org';
  static const String celoTestnetExplorer =
      'https://celo-sepolia.blockscout.com';

  static String get explorerUrl =>
      useTestnet ? celoTestnetExplorer : celoMainnetExplorer;

  // Contract Addresses - DEPLOYED TO SEPOLIA TESTNET
  static const String merchantRegistryMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy to mainnet
  static const String merchantRegistryTestnet =
      '0x8d84bB7d706DDDF2406C9584B1a2d5e0A740ebd2'; // ✅ Deployed on Celo Sepolia (Chain ID: 11142220) - Oct 26, 2025 (Updated)

  static const String loanEscrowMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy to mainnet
  static const String loanEscrowTestnet =
      '0xA692dF938c107d358543eCDa9a91a291ec9A8B8F'; // ✅ Deployed on Celo Sepolia (Chain ID: 11142220) - Oct 26, 2025 (Updated)

  static const String paymentProcessorMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy to mainnet
  static const String paymentProcessorTestnet =
      '0xBe5893D9E56d79bdC84C4647184dCB3b772c04D9'; // ✅ Deployed on Celo Sepolia (Chain ID: 11142220) - Oct 26, 2025 (Updated)

  static const String creditScoreOracleMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy to mainnet
  static const String creditScoreOracleTestnet =
      '0x6CE459798353B4Bd0396CA7b4b6893CC26140C41'; // ✅ Deployed on Celo Sepolia (Chain ID: 11142220) - Oct 26, 2025 (Updated)

  static String get merchantRegistryAddress =>
      useTestnet ? merchantRegistryTestnet : merchantRegistryMainnet;
  static String get loanEscrowAddress =>
      useTestnet ? loanEscrowTestnet : loanEscrowMainnet;
  static String get paymentProcessorAddress =>
      useTestnet ? paymentProcessorTestnet : paymentProcessorMainnet;
  static String get creditScoreOracleAddress =>
      useTestnet ? creditScoreOracleTestnet : creditScoreOracleMainnet;

  // Faucet URL
  static const String faucetUrl = 'https://faucet.celo.org';

  // WalletConnect Project ID
  // Get yours from: https://cloud.reown.com/
  static const String walletConnectProjectId = '1a1effd333a39e7b304741e7b04b8825';
}
