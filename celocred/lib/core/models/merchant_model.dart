
/// Merchant model
class Merchant {
  final String id;
  final String walletAddress;
  final String businessName;
  final String? avatar;
  final String category;
  final String? location;
  final String? description;
  final DateTime registeredDate;
  final double totalSales;
  final int transactionCount;
  final int creditScore;
  final List<String> badges;

  Merchant({
    required this.id,
    required this.walletAddress,
    required this.businessName,
    this.avatar,
    required this.category,
    this.location,
    this.description,
    DateTime? registeredDate,
    this.totalSales = 0.0,
    this.transactionCount = 0,
    this.creditScore = 0,
    this.badges = const [],
  }) : registeredDate = registeredDate ?? DateTime.now();

  Merchant copyWith({
    String? id,
    String? walletAddress,
    String? businessName,
    String? avatar,
    String? category,
    String? location,
    String? description,
    DateTime? registeredDate,
    double? totalSales,
    int? transactionCount,
    int? creditScore,
    List<String>? badges,
  }) {
    return Merchant(
      id: id ?? this.id,
      walletAddress: walletAddress ?? this.walletAddress,
      businessName: businessName ?? this.businessName,
      avatar: avatar ?? this.avatar,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      registeredDate: registeredDate ?? this.registeredDate,
      totalSales: totalSales ?? this.totalSales,
      transactionCount: transactionCount ?? this.transactionCount,
      creditScore: creditScore ?? this.creditScore,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletAddress': walletAddress,
      'businessName': businessName,
      'avatar': avatar,
      'category': category,
      'location': location,
      'description': description,
      'registeredDate': registeredDate.toIso8601String(),
      'totalSales': totalSales,
      'transactionCount': transactionCount,
      'creditScore': creditScore,
      'badges': badges,
    };
  }

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as String,
      walletAddress: json['walletAddress'] as String,
      businessName: json['businessName'] as String,
      avatar: json['avatar'] as String?,
      category: json['category'] as String,
      location: json['location'] as String?,
      description: json['description'] as String?,
      registeredDate: json['registeredDate'] != null
          ? DateTime.parse(json['registeredDate'] as String)
          : DateTime.now(),
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      creditScore: (json['creditScore'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  String get displayCreditScore => (creditScore / 10).round().toString();

  String get creditScoreTier {
    final displayScore = creditScore / 10;
    if (displayScore >= 70) return 'Excellent';
    if (displayScore >= 50) return 'Fair';
    return 'Growing';
  }

  @override
  String toString() {
    return 'Merchant(businessName: $businessName, score: $creditScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Merchant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Business categories
class BusinessCategory {
  static const String foodBeverage = 'Food & Beverage';
  static const String retail = 'Retail';
  static const String services = 'Services';
  static const String agriculture = 'Agriculture';
  static const String fashion = 'Fashion';
  static const String technology = 'Technology';
  static const String other = 'Other';

  static List<String> get all => [
        foodBeverage,
        retail,
        services,
        agriculture,
        fashion,
        technology,
        other,
      ];
}
