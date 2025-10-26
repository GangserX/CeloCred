import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanStatus {
  draft,
  pending,
  underReview,
  approved,
  disbursed,
  listed, // on marketplace
  funded, // fully funded
  repaying,
  repaid,
  defaulted,
  liquidated,
  rejected,
}

enum LoanPurpose {
  inventory,
  equipment,
  marketing,
  expansion,
  other,
}

/// Loan model
class Loan {
  final String id;
  final String merchantId;
  final String merchantWallet;
  final double amount;
  final double interestRate;
  final int termDays;
  final LoanPurpose purpose;
  final String? purposeNote;
  final LoanStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? dueDate;
  final double totalRepaymentAmount;
  final double paidAmount;
  final bool hasCollateral;
  final String? nftCollateralId;
  final bool autoRepaymentEnabled;
  final double autoRepaymentPercentage;
  final int creditScoreAtRequest;
  final List<String> lenderAddresses;
  final Map<String, double> lenderContributions;
  final String? rejectionReason;

  Loan({
    required this.id,
    required this.merchantId,
    required this.merchantWallet,
    required this.amount,
    required this.interestRate,
    required this.termDays,
    required this.purpose,
    this.purposeNote,
    required this.status,
    DateTime? requestedAt,
    this.approvedAt,
    this.disbursedAt,
    this.dueDate,
    double? totalRepaymentAmount,
    this.paidAmount = 0.0,
    this.hasCollateral = false,
    this.nftCollateralId,
    this.autoRepaymentEnabled = false,
    this.autoRepaymentPercentage = 0.0,
    this.creditScoreAtRequest = 0,
    this.lenderAddresses = const [],
    this.lenderContributions = const {},
    this.rejectionReason,
  })  : requestedAt = requestedAt ?? DateTime.now(),
        totalRepaymentAmount =
            totalRepaymentAmount ?? (amount + (amount * interestRate / 100));

  double get fundedAmount {
    return lenderContributions.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double get fundingProgress => amount > 0 ? (fundedAmount / amount) * 100 : 0;

  bool get isFullyFunded => fundedAmount >= amount;

  double get remainingAmount => (totalRepaymentAmount - paidAmount).clamp(0, double.infinity);

  double get repaymentProgress =>
      totalRepaymentAmount > 0 ? (paidAmount / totalRepaymentAmount) * 100 : 0;

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'merchantWallet': merchantWallet,
      'amount': amount,
      'interestRate': interestRate,
      'termDays': termDays,
      'purpose': purpose.name,
      'purposeNote': purposeNote,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'disbursedAt': disbursedAt != null ? Timestamp.fromDate(disbursedAt!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'totalRepaymentAmount': totalRepaymentAmount,
      'paidAmount': paidAmount,
      'hasCollateral': hasCollateral,
      'nftCollateralId': nftCollateralId,
      'autoRepaymentEnabled': autoRepaymentEnabled,
      'autoRepaymentPercentage': autoRepaymentPercentage,
      'creditScoreAtRequest': creditScoreAtRequest,
      'lenderAddresses': lenderAddresses,
      'lenderContributions': lenderContributions,
      'rejectionReason': rejectionReason,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String,
      merchantWallet: json['merchantWallet'] as String,
      amount: (json['amount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      termDays: json['termDays'] as int,
      purpose: LoanPurpose.values.firstWhere(
        (e) => e.name == json['purpose'],
        orElse: () => LoanPurpose.other,
      ),
      purposeNote: json['purposeNote'] as String?,
      status: LoanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LoanStatus.pending,
      ),
      requestedAt: _parseDateTime(json['requestedAt']),
      approvedAt: json['approvedAt'] != null ? _parseDateTime(json['approvedAt']) : null,
      disbursedAt: json['disbursedAt'] != null ? _parseDateTime(json['disbursedAt']) : null,
      dueDate: json['dueDate'] != null ? _parseDateTime(json['dueDate']) : null,
      totalRepaymentAmount: (json['totalRepaymentAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      hasCollateral: json['hasCollateral'] as bool? ?? false,
      nftCollateralId: json['nftCollateralId'] as String?,
      autoRepaymentEnabled: json['autoRepaymentEnabled'] as bool? ?? false,
      autoRepaymentPercentage:
          (json['autoRepaymentPercentage'] as num?)?.toDouble() ?? 0.0,
      creditScoreAtRequest: (json['creditScoreAtRequest'] as num?)?.toInt() ?? 0,
      lenderAddresses:
          (json['lenderAddresses'] as List<dynamic>?)?.cast<String>() ?? [],
      lenderContributions:
          (json['lenderContributions'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ) ??
              {},
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // Helper to parse DateTime from Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  // Create from Firebase document
  factory Loan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Use document ID
    return Loan.fromJson(data);
  }

  Loan copyWith({
    String? id,
    String? merchantId,
    String? merchantWallet,
    double? amount,
    double? interestRate,
    int? termDays,
    LoanPurpose? purpose,
    String? purposeNote,
    LoanStatus? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? disbursedAt,
    DateTime? dueDate,
    double? totalRepaymentAmount,
    double? paidAmount,
    bool? hasCollateral,
    String? nftCollateralId,
    bool? autoRepaymentEnabled,
    double? autoRepaymentPercentage,
    int? creditScoreAtRequest,
    List<String>? lenderAddresses,
    Map<String, double>? lenderContributions,
    String? rejectionReason,
  }) {
    return Loan(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      merchantWallet: merchantWallet ?? this.merchantWallet,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      termDays: termDays ?? this.termDays,
      purpose: purpose ?? this.purpose,
      purposeNote: purposeNote ?? this.purposeNote,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      dueDate: dueDate ?? this.dueDate,
      totalRepaymentAmount: totalRepaymentAmount ?? this.totalRepaymentAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      hasCollateral: hasCollateral ?? this.hasCollateral,
      nftCollateralId: nftCollateralId ?? this.nftCollateralId,
      autoRepaymentEnabled: autoRepaymentEnabled ?? this.autoRepaymentEnabled,
      autoRepaymentPercentage:
          autoRepaymentPercentage ?? this.autoRepaymentPercentage,
      creditScoreAtRequest: creditScoreAtRequest ?? this.creditScoreAtRequest,
      lenderAddresses: lenderAddresses ?? this.lenderAddresses,
      lenderContributions: lenderContributions ?? this.lenderContributions,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
