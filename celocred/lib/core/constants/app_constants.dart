/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'CeloCred';
  static const String appTagline = 'Decentralized Credit for Small Businesses';
  static const String appVersion = '1.0.0';

  // Credit Scoring
  static const int minCreditScore = 0;
  static const int maxCreditScore = 1000;
  static const int displayMinScore = 0;
  static const int displayMaxScore = 100;

  // Credit Score Thresholds
  static const int excellentScoreThreshold = 70; // Green
  static const int fairScoreThreshold = 50; // Yellow
  // Below 50 = Poor (Red)

  // Credit Score Weights
  static const double weightTransactionActivity = 0.18;
  static const double weightTransactionVolume = 0.12;
  static const double weightRepaymentHistory = 0.20;
  static const double weightCashFlow = 0.12;
  static const double weightBusinessTenure = 0.10;
  static const double weightBusinessDiversity = 0.08;
  static const double weightBehavioralTrust = 0.10;
  static const double weightDefaultPenalty = 0.10;

  // Scoring Caps (for normalization)
  static const int capTransactionCount = 200; // transactions in 90 days
  static const int capTransactionAmount = 50000; // cUSD in 90 days
  static const int capMonthlyCashflow = 10000; // cUSD per month
  static const int capBusinessTenureMonths = 24; // months
  static const int capUniquePayers = 50; // unique customers
  static const int capDefaultLoans = 5; // defaults

  // Loan Configuration
  static const double overCollateralRatio = 1.5; // 150%
  static const double coldStartOverCollateralRatio = 2.5; // 250%
  static const int autoApproveScoreThreshold = 700; // 70/100 display
  static const int crowdLendScoreThreshold = 400; // 40/100 display
  static const int minRepaymentRate = 80; // 80% for auto-approval

  // Loan Limits
  static const double coldStartMaxLoan = 50.0; // cUSD
  static const double maxPlatformLoan = 5000.0; // cUSD
  static const double minLoanAmount = 10.0; // cUSD
  static const double manualReviewThreshold = 1000.0; // cUSD

  // Loan Terms
  static const List<int> repaymentPeriodOptions = [30, 60, 90]; // days
  static const int defaultGracePeriod = 7; // days after due date
  static const int auctionDuration = 72; // hours
  static const double minBidFactor = 0.9; // 90% of required collateral

  // Transaction Timeframes
  static const int scoringWindowDays = 90; // last 90 days for scoring
  static const int recentActivityDays = 30; // recent activity window

  // Behavioral Flags
  static const double maxSelfTransferRatio = 0.2; // 20%
  static const double maxLargeSingleTxRatio = 0.5; // 50%
  static const int minUniquePayers = 3; // minimum for fast approval

  // Auto-repayment
  static const double minAutoRepaymentPercentage = 5.0; // 5%
  static const double maxAutoRepaymentPercentage = 20.0; // 20%

  // Interest Rates (APR)
  static const double baseInterestRate = 12.0; // 12% APR
  static const double collateralInterestDiscount = 4.0; // -4% with collateral
  static const double highScoreInterestDiscount = 2.0; // -2% for score > 80

  // UI
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // Animations
  static const int animationDurationMs = 300;
  static const int loadingSimulationMs = 3000;

  // Storage Keys
  static const String storageKeyWalletAddress = 'wallet_address';
  static const String storageKeyPrivateKey = 'private_key';
  static const String storageKeyMnemonic = 'mnemonic';
  static const String storageKeyMerchantId = 'merchant_id';
  static const String storageKeyUserType = 'user_type';

  // WalletConnect
  static const String walletConnectProjectId =
      'YOUR_WALLETCONNECT_PROJECT_ID'; // Get from https://cloud.walletconnect.com
  static const String valoraDeepLink = 'celo://wallet';

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Pagination
  static const int marketplacePageSize = 10;
  static const int transactionPageSize = 20;
}
