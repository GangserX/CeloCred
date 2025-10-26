/// Credit Score Breakdown Components
library;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreditScoreBreakdown {
  final double transactionActivity; // 0-100
  final double transactionVolume; // 0-100
  final double repaymentHistory; // 0-100
  final double cashFlowMetrics; // 0-100
  final double businessTenure; // 0-100
  final double businessDiversity; // 0-100
  final double behavioralTrust; // 0-100
  final double defaultPenalty; // 0-100 (negative impact)

  // Raw data for display
  final int totalTransactions90Days;
  final double totalVolume90Days;
  final double avgTransactionAmount;
  final int uniquePayers;
  final int loansRepaid;
  final int loansDefaulted;
  final double onTimeRepaymentRate;
  final double avgMonthlyCashflow;
  final double cashflowVolatility;
  final int accountAgeMonths;
  final double selfTransferRatio;
  final bool washTradeFlag;

  CreditScoreBreakdown({
    required this.transactionActivity,
    required this.transactionVolume,
    required this.repaymentHistory,
    required this.cashFlowMetrics,
    required this.businessTenure,
    required this.businessDiversity,
    required this.behavioralTrust,
    required this.defaultPenalty,
    required this.totalTransactions90Days,
    required this.totalVolume90Days,
    required this.avgTransactionAmount,
    required this.uniquePayers,
    required this.loansRepaid,
    required this.loansDefaulted,
    required this.onTimeRepaymentRate,
    required this.avgMonthlyCashflow,
    required this.cashflowVolatility,
    required this.accountAgeMonths,
    required this.selfTransferRatio,
    required this.washTradeFlag,
  });

  double get overallScore {
    return (transactionActivity * 0.18) +
        (transactionVolume * 0.12) +
        (repaymentHistory * 0.20) +
        (cashFlowMetrics * 0.12) +
        (businessTenure * 0.10) +
        (businessDiversity * 0.08) +
        (behavioralTrust * 0.10) -
        (defaultPenalty * 0.10);
  }

  int get finalScore => (overallScore * 10).clamp(0, 1000).round();
  int get displayScore => (overallScore).clamp(0, 100).round();

  String get tier {
    if (displayScore >= 70) return 'Excellent';
    if (displayScore >= 50) return 'Fair';
    return 'Growing';
  }

  Color get tierColor {
    if (displayScore >= 70) return Colors.green;
    if (displayScore >= 50) return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionActivity': transactionActivity,
      'transactionVolume': transactionVolume,
      'repaymentHistory': repaymentHistory,
      'cashFlowMetrics': cashFlowMetrics,
      'businessTenure': businessTenure,
      'businessDiversity': businessDiversity,
      'behavioralTrust': behavioralTrust,
      'defaultPenalty': defaultPenalty,
      'totalTransactions90Days': totalTransactions90Days,
      'totalVolume90Days': totalVolume90Days,
      'avgTransactionAmount': avgTransactionAmount,
      'uniquePayers': uniquePayers,
      'loansRepaid': loansRepaid,
      'loansDefaulted': loansDefaulted,
      'onTimeRepaymentRate': onTimeRepaymentRate,
      'avgMonthlyCashflow': avgMonthlyCashflow,
      'cashflowVolatility': cashflowVolatility,
      'accountAgeMonths': accountAgeMonths,
      'selfTransferRatio': selfTransferRatio,
      'washTradeFlag': washTradeFlag,
    };
  }

  factory CreditScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return CreditScoreBreakdown(
      transactionActivity: (json['transactionActivity'] as num).toDouble(),
      transactionVolume: (json['transactionVolume'] as num).toDouble(),
      repaymentHistory: (json['repaymentHistory'] as num).toDouble(),
      cashFlowMetrics: (json['cashFlowMetrics'] as num).toDouble(),
      businessTenure: (json['businessTenure'] as num).toDouble(),
      businessDiversity: (json['businessDiversity'] as num).toDouble(),
      behavioralTrust: (json['behavioralTrust'] as num).toDouble(),
      defaultPenalty: (json['defaultPenalty'] as num).toDouble(),
      totalTransactions90Days: json['totalTransactions90Days'] as int,
      totalVolume90Days: (json['totalVolume90Days'] as num).toDouble(),
      avgTransactionAmount: (json['avgTransactionAmount'] as num).toDouble(),
      uniquePayers: json['uniquePayers'] as int,
      loansRepaid: json['loansRepaid'] as int,
      loansDefaulted: json['loansDefaulted'] as int,
      onTimeRepaymentRate: (json['onTimeRepaymentRate'] as num).toDouble(),
      avgMonthlyCashflow: (json['avgMonthlyCashflow'] as num).toDouble(),
      cashflowVolatility: (json['cashflowVolatility'] as num).toDouble(),
      accountAgeMonths: json['accountAgeMonths'] as int,
      selfTransferRatio: (json['selfTransferRatio'] as num).toDouble(),
      washTradeFlag: json['washTradeFlag'] as bool,
    );
  }

  // Create from Firebase document
  factory CreditScoreBreakdown.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditScoreBreakdown.fromJson(data['factors'] ?? data);
  }

  factory CreditScoreBreakdown.empty() {
    return CreditScoreBreakdown(
      transactionActivity: 0,
      transactionVolume: 0,
      repaymentHistory: 0,
      cashFlowMetrics: 0,
      businessTenure: 0,
      businessDiversity: 0,
      behavioralTrust: 0,
      defaultPenalty: 0,
      totalTransactions90Days: 0,
      totalVolume90Days: 0,
      avgTransactionAmount: 0,
      uniquePayers: 0,
      loansRepaid: 0,
      loansDefaulted: 0,
      onTimeRepaymentRate: 0,
      avgMonthlyCashflow: 0,
      cashflowVolatility: 0,
      accountAgeMonths: 0,
      selfTransferRatio: 0,
      washTradeFlag: false,
    );
  }
}
