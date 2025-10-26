/// NFT Collateral model
class NFTCollateral {
  final String id;
  final String loanId;
  final String nftContractAddress;
  final String tokenId;
  final String? name;
  final String? description;
  final String? imageUrl;
  final double estimatedValue;
  final double requiredCollateral;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime? unlockedAt;
  final String? auctionId;
  final bool isInAuction;

  NFTCollateral({
    required this.id,
    required this.loanId,
    required this.nftContractAddress,
    required this.tokenId,
    this.name,
    this.description,
    this.imageUrl,
    required this.estimatedValue,
    required this.requiredCollateral,
    this.isLocked = false,
    this.lockedAt,
    this.unlockedAt,
    this.auctionId,
    this.isInAuction = false,
  });

  double get collateralizationRatio =>
      requiredCollateral > 0 ? (estimatedValue / requiredCollateral) * 100 : 0;

  bool get isSufficientCollateral => estimatedValue >= requiredCollateral;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'nftContractAddress': nftContractAddress,
      'tokenId': tokenId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'estimatedValue': estimatedValue,
      'requiredCollateral': requiredCollateral,
      'isLocked': isLocked,
      'lockedAt': lockedAt?.toIso8601String(),
      'unlockedAt': unlockedAt?.toIso8601String(),
      'auctionId': auctionId,
      'isInAuction': isInAuction,
    };
  }

  factory NFTCollateral.fromJson(Map<String, dynamic> json) {
    return NFTCollateral(
      id: json['id'] as String,
      loanId: json['loanId'] as String,
      nftContractAddress: json['nftContractAddress'] as String,
      tokenId: json['tokenId'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
      requiredCollateral: (json['requiredCollateral'] as num).toDouble(),
      isLocked: json['isLocked'] as bool? ?? false,
      lockedAt: json['lockedAt'] != null
          ? DateTime.parse(json['lockedAt'] as String)
          : null,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      auctionId: json['auctionId'] as String?,
      isInAuction: json['isInAuction'] as bool? ?? false,
    );
  }
}
