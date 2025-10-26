import 'dart:math';
import '../constants/app_constants.dart';
import '../models/credit_score_model.dart';
import '../models/transaction_model.dart';

/// Credit Scoring Service - Calculates merchant creditworthiness
class CreditScoringService {
  /// Calculate complete credit score for a merchant
  CreditScoreBreakdown calculateCreditScore({
    required List<Transaction> transactions,
    required int loansRepaid,
    required int loansDefaulted,
    required DateTime accountCreatedDate,
    String? merchantWallet,
  }) {
    // Filter transactions to last 90 days
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: AppConstants.scoringWindowDays));
    final recentTxs = transactions.where((tx) => tx.timestamp.isAfter(ninetyDaysAgo)).toList();

    // Extract metrics
    final totalTxCount = recentTxs.length;
    final totalVolume = recentTxs.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final avgTxAmount = totalTxCount > 0 ? totalVolume / totalTxCount : 0.0;

    // Unique payers (distinct 'from' addresses)
    final uniquePayers = recentTxs.map((tx) => tx.from).toSet().length;

    // Calculate daily transaction counts for volatility
    final dailyCounts = <int>[];
    for (int i = 0; i < 90; i++) {
      final date = ninetyDaysAgo.add(Duration(days: i));
      final count = recentTxs.where((tx) {
        return tx.timestamp.year == date.year &&
            tx.timestamp.month == date.month &&
            tx.timestamp.day == date.day;
      }).length;
      dailyCounts.add(count);
    }

    final avgDailyTxs = dailyCounts.isNotEmpty
        ? dailyCounts.reduce((a, b) => a + b) / dailyCounts.length
        : 0.0;
    final txVolatility = _calculateStdDev(dailyCounts);
    final cashflowStability = avgDailyTxs > 0
        ? (1 - (txVolatility / (avgDailyTxs + 0.1))).clamp(0.0, 1.0)
        : 0.0;

    // Cash flow metrics
    final avgMonthlyCashflow = totalVolume / 3; // 90 days = 3 months

    // Business tenure
    final accountAgeMonths = now.difference(accountCreatedDate).inDays ~/ 30;

    // Repayment history
    final totalLoans = loansRepaid + loansDefaulted;
    final onTimeRepaymentRate = totalLoans > 0 ? loansRepaid / totalLoans : 0.0;

    // Behavioral flags
    double selfTransferRatio = 0.0;
    bool washTradeFlag = false;
    
    if (merchantWallet != null && recentTxs.isNotEmpty) {
      final selfTransfers = recentTxs.where((tx) =>
          tx.from.toLowerCase() == merchantWallet.toLowerCase() ||
          tx.to.toLowerCase() == merchantWallet.toLowerCase()).length;
      selfTransferRatio = selfTransfers / recentTxs.length;
      
      // Simple wash trade detection: high self-transfer ratio
      washTradeFlag = selfTransferRatio > 0.5;
    }

    // Normalize scores (0-100)
    final sTxactivity = _normalize(
      totalTxCount.toDouble(),
      AppConstants.capTransactionCount.toDouble(),
    );
    
    final sTxvolume = _normalize(
      totalVolume,
      AppConstants.capTransactionAmount.toDouble(),
    );
    
    final sRepaymenthistory = onTimeRepaymentRate * 100;
    
    final sDefaultpenalty = _normalize(
      loansDefaulted.toDouble(),
      AppConstants.capDefaultLoans.toDouble(),
    );
    
    final sCashflow = _normalize(
      avgMonthlyCashflow,
      AppConstants.capMonthlyCashflow.toDouble(),
    );
    
    final sStability = cashflowStability * 100;
    
    final sTenure = _normalize(
      accountAgeMonths.toDouble(),
      AppConstants.capBusinessTenureMonths.toDouble(),
    );
    
    final sDiversity = _normalize(
      uniquePayers.toDouble(),
      AppConstants.capUniquePayers.toDouble(),
    );
    
    // Behavioral trust score (inverse of risk)
    final behaviorRiskScore = (50 * selfTransferRatio) +
        (washTradeFlag ? 40 : 0);
    final sBehaviortrust = (100 - behaviorRiskScore).clamp(0.0, 100.0);

    return CreditScoreBreakdown(
      transactionActivity: sTxactivity,
      transactionVolume: sTxvolume,
      repaymentHistory: sRepaymenthistory,
      cashFlowMetrics: sCashflow,
      businessTenure: sTenure,
      businessDiversity: sDiversity,
      behavioralTrust: sBehaviortrust,
      defaultPenalty: sDefaultpenalty,
      totalTransactions90Days: totalTxCount,
      totalVolume90Days: totalVolume,
      avgTransactionAmount: avgTxAmount,
      uniquePayers: uniquePayers,
      loansRepaid: loansRepaid,
      loansDefaulted: loansDefaulted,
      onTimeRepaymentRate: onTimeRepaymentRate,
      avgMonthlyCashflow: avgMonthlyCashflow,
      cashflowVolatility: txVolatility,
      accountAgeMonths: accountAgeMonths,
      selfTransferRatio: selfTransferRatio,
      washTradeFlag: washTradeFlag,
    );
  }

  /// Determine loan approval decision
  Map<String, dynamic> evaluateLoanRequest({
    required CreditScoreBreakdown creditScore,
    required double loanAmount,
    required bool hasCollateral,
    double collateralValue = 0.0,
  }) {
    final score = creditScore.displayScore;
    final behaviorRiskScore = 100 - creditScore.behavioralTrust;

    // Check for immediate rejection
    if (creditScore.washTradeFlag && behaviorRiskScore > 50) {
      return {
        'decision': 'REJECTED',
        'reason': 'High risk behavioral patterns detected',
        'suggestions': [
          'Build legitimate transaction history',
          'Reduce self-transfers',
          'Increase customer diversity',
        ],
      };
    }

    if (score < 30 && !hasCollateral) {
      return {
        'decision': 'REJECTED',
        'reason': 'Insufficient credit score and no collateral',
        'suggestions': [
          'Build transaction history (need 50+ transactions)',
          'Consider offering NFT collateral',
          'Start with smaller pilot loan (${AppConstants.coldStartMaxLoan} cUSD)',
        ],
      };
    }

    // Check for auto-approval
    if (score >= 70 &&
        creditScore.onTimeRepaymentRate >= 0.8 &&
        loanAmount <= AppConstants.maxPlatformLoan &&
        behaviorRiskScore <= 30) {
      return {
        'decision': 'APPROVED',
        'reason': 'Excellent credit score and history',
        'interest_rate': _calculateInterestRate(score, hasCollateral),
      };
    }

    // Collateralized approval
    if (hasCollateral && collateralValue >= loanAmount * AppConstants.overCollateralRatio) {
      return {
        'decision': 'APPROVED',
        'reason': 'Sufficient collateral provided',
        'interest_rate': _calculateInterestRate(score, hasCollateral),
      };
    }

    // Manual review needed
    if ((score >= 50 && score < 70) ||
        behaviorRiskScore > 30 ||
        creditScore.loansDefaulted > 0 ||
        loanAmount > AppConstants.manualReviewThreshold) {
      return {
        'decision': 'MANUAL_REVIEW',
        'reason': 'Requires additional verification',
        'factors': [
          if (score < 70) 'Borderline credit score',
          if (behaviorRiskScore > 30) 'Elevated behavioral risk',
          if (creditScore.loansDefaulted > 0) 'Previous defaults',
          if (loanAmount > AppConstants.manualReviewThreshold) 'Large loan amount',
        ],
      };
    }

    // Crowd-lend (marketplace)
    if (score >= 40) {
      return {
        'decision': 'CROWD_LEND',
        'reason': 'Eligible for community funding',
        'interest_rate': _calculateInterestRate(score, hasCollateral),
      };
    }

    // Default to rejection
    return {
      'decision': 'REJECTED',
      'reason': 'Does not meet minimum requirements',
      'suggestions': [
        'Increase transaction volume',
        'Build longer business history',
        'Consider smaller loan amount',
      ],
    };
  }

  /// Calculate interest rate based on score and collateral
  double _calculateInterestRate(int score, bool hasCollateral) {
    double rate = AppConstants.baseInterestRate;
    
    // Discount for high score
    if (score >= 80) {
      rate -= AppConstants.highScoreInterestDiscount;
    }
    
    // Discount for collateral
    if (hasCollateral) {
      rate -= AppConstants.collateralInterestDiscount;
    }
    
    return rate.clamp(5.0, 20.0); // Min 5%, Max 20%
  }

  /// Normalize value to 0-100 range
  double _normalize(double value, double cap) {
    return (value / cap * 100).clamp(0.0, 100.0);
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<int> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }
}
