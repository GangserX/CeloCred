/// Celo Blockchain Configuration
class CeloConfig {
  // Network Selection
  static const bool useTestnet = true; // Set to false for mainnet

  // Chain IDs
  static const int celoMainnetChainId = 42220;
  static const int celoAlfajoresChainId = 44787;

  static int get chainId =>
      useTestnet ? celoAlfajoresChainId : celoMainnetChainId;

  // RPC Endpoints
  static const String celoMainnetRpc = 'https://forno.celo.org';
  static const String celoAlfajoresRpc =
      'https://alfajores-forno.celo-testnet.org';

  static String get rpcUrl => useTestnet ? celoAlfajoresRpc : celoMainnetRpc;

  // Token Addresses - Mainnet
  static const String celoMainnetAddress =
      '0x471EcE3750Da237f93B8E339c536989b8978a438';
  static const String cUSDMainnetAddress =
      '0x765DE816845861e75A25fCA122bb6898B8B1282a';
  static const String cEURMainnetAddress =
      '0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73';

  // Token Addresses - Alfajores Testnet
  static const String celoAlfajoresAddress =
      '0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9';
  static const String cUSDAlfajoresAddress =
      '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1';
  static const String cEURAlfajoresAddress =
      '0x10c892A6EC43a53E45D0B916B4b7D383B1b78C0F';

  // Get current network addresses
  static String get celoAddress =>
      useTestnet ? celoAlfajoresAddress : celoMainnetAddress;
  static String get cUSDAddress =>
      useTestnet ? cUSDAlfajoresAddress : cUSDMainnetAddress;
  static String get cEURAddress =>
      useTestnet ? cEURAlfajoresAddress : cEURMainnetAddress;

  // Gas Configuration
  static const int defaultGasLimit = 200000;
  static const String defaultGasPrice = '1000000000'; // 1 Gwei

  // Explorer URLs
  static const String celoMainnetExplorer = 'https://explorer.celo.org';
  static const String celoAlfajoresExplorer =
      'https://alfajores-blockscout.celo-testnet.org';

  static String get explorerUrl =>
      useTestnet ? celoAlfajoresExplorer : celoMainnetExplorer;

  // Contract Addresses - DEPLOYED TO ALFAJORES TESTNET
  static const String merchantRegistryMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy
  static const String merchantRegistryTestnet =
      '0x161DA951ba19DEac6a281e22C725829D28735eC4'; // ✅ Deployed (Oct 26, 2025)

  static const String loanEscrowMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy
  static const String loanEscrowTestnet =
      '0x11D6DaF8A38ccaa156C077309Dd4C86A1cFE9E68'; // ✅ Deployed (Oct 26, 2025)

  static const String paymentProcessorMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy
  static const String paymentProcessorTestnet =
      '0x56fC686df48b1e7EC99a8d48fCab37844F87b3Ad'; // ✅ Deployed (Oct 26, 2025)

  static const String creditScoreOracleMainnet =
      '0x0000000000000000000000000000000000000000'; // TODO: Deploy
  static const String creditScoreOracleTestnet =
      '0xaF04bC6b274d6De4e6d260BDFA6B57EB14fd3C4c'; // ✅ Deployed (Oct 26, 2025)

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
