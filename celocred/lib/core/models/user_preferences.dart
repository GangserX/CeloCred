import 'package:cloud_firestore/cloud_firestore.dart';

/// User Preferences - Analytics and settings stored in Firebase
class UserPreferences {
  final String walletAddress;
  final DateTime lastLogin;
  final String deviceInfo;
  final Map<String, bool> notificationPreferences;
  final bool tutorialCompleted;

  UserPreferences({
    required this.walletAddress,
    required this.lastLogin,
    required this.deviceInfo,
    required this.notificationPreferences,
    this.tutorialCompleted = false,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'walletAddress': walletAddress,
      'lastLogin': Timestamp.fromDate(lastLogin),
      'deviceInfo': deviceInfo,
      'notificationPreferences': notificationPreferences,
      'tutorialCompleted': tutorialCompleted,
    };
  }

  // Create from Firebase document
  factory UserPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPreferences(
      walletAddress: data['walletAddress'] ?? '',
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceInfo: data['deviceInfo'] ?? '',
      notificationPreferences: Map<String, bool>.from(data['notificationPreferences'] ?? {}),
      tutorialCompleted: data['tutorialCompleted'] ?? false,
    );
  }

  // Create from Map
  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      walletAddress: data['walletAddress'] ?? '',
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceInfo: data['deviceInfo'] ?? '',
      notificationPreferences: Map<String, bool>.from(data['notificationPreferences'] ?? {}),
      tutorialCompleted: data['tutorialCompleted'] ?? false,
    );
  }
}
