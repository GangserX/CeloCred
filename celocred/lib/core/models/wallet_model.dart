
/// Wallet model
class Wallet {
  final String address;
  final String? privateKey;
  final String? mnemonic;
  final double celoBalance;
  final double cUSDBalance;
  final double cEURBalance;
  final DateTime createdAt;

  Wallet({
    required this.address,
    this.privateKey,
    this.mnemonic,
    this.celoBalance = 0.0,
    this.cUSDBalance = 0.0,
    this.cEURBalance = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Wallet copyWith({
    String? address,
    String? privateKey,
    String? mnemonic,
    double? celoBalance,
    double? cUSDBalance,
    double? cEURBalance,
    DateTime? createdAt,
  }) {
    return Wallet(
      address: address ?? this.address,
      privateKey: privateKey ?? this.privateKey,
      mnemonic: mnemonic ?? this.mnemonic,
      celoBalance: celoBalance ?? this.celoBalance,
      cUSDBalance: cUSDBalance ?? this.cUSDBalance,
      cEURBalance: cEURBalance ?? this.cEURBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'privateKey': privateKey,
      'mnemonic': mnemonic,
      'celoBalance': celoBalance,
      'cUSDBalance': cUSDBalance,
      'cEURBalance': cEURBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      address: json['address'] as String,
      privateKey: json['privateKey'] as String?,
      mnemonic: json['mnemonic'] as String?,
      celoBalance: (json['celoBalance'] as num?)?.toDouble() ?? 0.0,
      cUSDBalance: (json['cUSDBalance'] as num?)?.toDouble() ?? 0.0,
      cEURBalance: (json['cEURBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Wallet(address: $address, CELO: $celoBalance, cUSD: $cUSDBalance, cEUR: $cEURBalance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Wallet && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
