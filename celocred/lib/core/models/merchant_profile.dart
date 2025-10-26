import 'package:cloud_firestore/cloud_firestore.dart';

/// Merchant Profile - Stored in Firebase
class MerchantProfile {
  final String walletAddress;
  final String businessName;
  final String businessCategory;
  final String businessDescription;
  final String location;
  final String contactPhone;
  final String contactEmail;
  final String? logoUrl;
  final String kycStatus;
  final DateTime registeredAt;
  final DateTime lastUpdated;
  final bool isActive;

  MerchantProfile({
    required this.walletAddress,
    required this.businessName,
    required this.businessCategory,
    required this.businessDescription,
    required this.location,
    required this.contactPhone,
    required this.contactEmail,
    this.logoUrl,
    this.kycStatus = 'pending',
    required this.registeredAt,
    required this.lastUpdated,
    this.isActive = true,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'walletAddress': walletAddress,
      'businessName': businessName,
      'businessCategory': businessCategory,
      'businessDescription': businessDescription,
      'location': location,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'logoUrl': logoUrl,
      'kycStatus': kycStatus,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
    };
  }

  // Create from Firebase document
  factory MerchantProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantProfile(
      walletAddress: data['walletAddress'] ?? '',
      businessName: data['businessName'] ?? '',
      businessCategory: data['businessCategory'] ?? '',
      businessDescription: data['businessDescription'] ?? '',
      location: data['location'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      logoUrl: data['logoUrl'],
      kycStatus: data['kycStatus'] ?? 'pending',
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Create from Map
  factory MerchantProfile.fromMap(Map<String, dynamic> data) {
    return MerchantProfile(
      walletAddress: data['walletAddress'] ?? '',
      businessName: data['businessName'] ?? '',
      businessCategory: data['businessCategory'] ?? '',
      businessDescription: data['businessDescription'] ?? '',
      location: data['location'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      logoUrl: data['logoUrl'],
      kycStatus: data['kycStatus'] ?? 'pending',
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}
