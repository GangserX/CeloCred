import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, confirmed, failed }

enum TransactionType { payment, loanDisbursement, loanRepayment }

/// Transaction model
class Transaction {
  final String id;
  final String from;
  final String to;
  final double amount;
  final String currency; // 'CELO', 'cUSD', 'cEUR'
  final TransactionStatus status;
  final TransactionType type;
  final String? txHash;
  final DateTime timestamp;
  final String? note;

  Transaction({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    this.txHash,
    DateTime? timestamp,
    this.note,
  }) : timestamp = timestamp ?? DateTime.now();

  Transaction copyWith({
    String? id,
    String? from,
    String? to,
    double? amount,
    String? currency,
    TransactionStatus? status,
    TransactionType? type,
    String? txHash,
    DateTime? timestamp,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      type: type ?? this.type,
      txHash: txHash ?? this.txHash,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'type': type.name,
      'txHash': txHash,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.payment,
      ),
      txHash: json['txHash'] as String?,
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is Timestamp 
              ? (json['timestamp'] as Timestamp).toDate()
              : DateTime.parse(json['timestamp'] as String))
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }

  // Create from Firebase document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      from: data['from'] ?? data['customerAddress'] ?? '',
      to: data['to'] ?? data['merchantAddress'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'cUSD',
      status: data['status'] != null
          ? TransactionStatus.values.firstWhere(
              (e) => e.name == data['status'],
              orElse: () => TransactionStatus.confirmed,
            )
          : TransactionStatus.confirmed,
      type: data['type'] != null
          ? TransactionType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => TransactionType.payment,
            )
          : TransactionType.payment,
      txHash: data['txHash'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] ?? data['notes'],
    );
  }

  String get shortFrom => '${from.substring(0, 6)}...${from.substring(from.length - 4)}';
  String get shortTo => '${to.substring(0, 6)}...${to.substring(to.length - 4)}';
  String get shortTxHash =>
      txHash != null
          ? '${txHash!.substring(0, 6)}...${txHash!.substring(txHash!.length - 4)}'
          : 'N/A';

  @override
  String toString() {
    return 'Transaction(amount: $amount $currency, status: ${status.name})';
  }
}
