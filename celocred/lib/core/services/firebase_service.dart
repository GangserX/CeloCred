import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/merchant_profile.dart';
import '../models/user_preferences.dart';
import '../../firebase_options.dart';

/// Firebase Service - Handles all Firebase operations
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  bool _isInitialized = false;

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Import Firebase options
      final options = DefaultFirebaseOptions.currentPlatform;
      
      // Initialize with options
      await Firebase.initializeApp(options: options);
      
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _isInitialized = true;
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
      rethrow;
    }
  }

  // ========== MERCHANT OPERATIONS ==========

  /// Check if wallet address is a registered merchant
  Future<bool> isMerchant(String walletAddress) async {
    try {
      final doc = await _firestore
          .collection('merchants')
          .doc(walletAddress.toLowerCase())
          .get();
      return doc.exists && (doc.data()?['isActive'] ?? false);
    } catch (e) {
      print('❌ Error checking merchant status: $e');
      return false;
    }
  }

  /// Get merchant profile from Firebase
  Future<MerchantProfile?> getMerchantProfile(String walletAddress) async {
    try {
      final doc = await _firestore
          .collection('merchants')
          .doc(walletAddress.toLowerCase())
          .get();

      if (doc.exists) {
        return MerchantProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting merchant profile: $e');
      return null;
    }
  }

  /// Register new merchant in Firebase
  Future<void> registerMerchant(MerchantProfile merchant) async {
    try {
      await _firestore
          .collection('merchants')
          .doc(merchant.walletAddress.toLowerCase())
          .set(merchant.toJson());
      print('✅ Merchant registered: ${merchant.businessName}');
    } catch (e) {
      print('❌ Error registering merchant: $e');
      rethrow;
    }
  }

  /// Update merchant profile
  Future<void> updateMerchantProfile(String walletAddress, Map<String, dynamic> updates) async {
    try {
      updates['lastUpdated'] = Timestamp.now();
      await _firestore
          .collection('merchants')
          .doc(walletAddress.toLowerCase())
          .update(updates);
      print('✅ Merchant profile updated');
    } catch (e) {
      print('❌ Error updating merchant profile: $e');
      rethrow;
    }
  }

  // ========== CREDIT SCORE OPERATIONS ==========

  /// Get credit score from Firebase
  Future<Map<String, dynamic>?> getCreditScore(String walletAddress) async {
    try {
      final doc = await _firestore
          .collection('creditScores')
          .doc(walletAddress.toLowerCase())
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting credit score: $e');
      return null;
    }
  }

  /// Save/update credit score in Firebase
  Future<void> saveCreditScore(String walletAddress, int score, Map<String, dynamic> factors) async {
    try {
      await _firestore
          .collection('creditScores')
          .doc(walletAddress.toLowerCase())
          .set({
        'walletAddress': walletAddress.toLowerCase(),
        'score': score,
        'factors': factors,
        'calculatedAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });
      print('✅ Credit score saved: $score');
    } catch (e) {
      print('❌ Error saving credit score: $e');
      rethrow;
    }
  }

  // ========== USER PREFERENCES OPERATIONS ==========

  /// Get user preferences
  Future<UserPreferences?> getUserPreferences(String walletAddress) async {
    try {
      final doc = await _firestore
          .collection('userPreferences')
          .doc(walletAddress.toLowerCase())
          .get();

      if (doc.exists) {
        return UserPreferences.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user preferences: $e');
      return null;
    }
  }

  /// Save/update user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      await _firestore
          .collection('userPreferences')
          .doc(preferences.walletAddress.toLowerCase())
          .set(preferences.toJson());
      print('✅ User preferences saved');
    } catch (e) {
      print('❌ Error saving user preferences: $e');
      rethrow;
    }
  }

  /// Update last login time
  Future<void> updateLastLogin(String walletAddress) async {
    try {
      await _firestore
          .collection('userPreferences')
          .doc(walletAddress.toLowerCase())
          .set({
        'walletAddress': walletAddress.toLowerCase(),
        'lastLogin': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error updating last login: $e');
    }
  }

  // ========== STORAGE OPERATIONS ==========

  /// Upload merchant logo to Firebase Storage
  Future<String?> uploadMerchantLogo(String walletAddress, String filePath) async {
    try {
      final ref = _storage.ref().child('merchant_logos/${walletAddress.toLowerCase()}.jpg');
      await ref.putFile(filePath as dynamic); // Will need proper file handling
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('❌ Error uploading logo: $e');
      return null;
    }
  }

  // ========== QUERY OPERATIONS ==========

  /// Get all merchants (for marketplace/listing)
  Future<List<MerchantProfile>> getAllMerchants({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('merchants')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MerchantProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting merchants: $e');
      return [];
    }
  }

  /// Search merchants by category
  Future<List<MerchantProfile>> searchMerchantsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('merchants')
          .where('businessCategory', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => MerchantProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error searching merchants: $e');
      return [];
    }
  }

  // ========== TRANSACTION OPERATIONS ==========

  /// Get merchant's payment transactions
  Future<List<Map<String, dynamic>>> getMerchantTransactions(
    String walletAddress, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('merchantAddress', isEqualTo: walletAddress.toLowerCase())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting merchant transactions: $e');
      return [];
    }
  }

  /// Get merchant statistics
  Future<Map<String, dynamic>> getMerchantStats(String walletAddress) async {
    try {
      final transactions = await getMerchantTransactions(walletAddress);
      
      double totalRevenue = 0;
      int totalTransactions = transactions.length;
      int todayTransactions = 0;
      double todayRevenue = 0;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (var tx in transactions) {
        final amount = (tx['amount'] ?? 0).toDouble();
        totalRevenue += amount;
        
        // Check if transaction is from today
        if (tx['timestamp'] != null) {
          final txDate = (tx['timestamp'] as Timestamp).toDate();
          final txDay = DateTime(txDate.year, txDate.month, txDate.day);
          if (txDay.isAtSameMomentAs(today)) {
            todayTransactions++;
            todayRevenue += amount;
          }
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalTransactions': totalTransactions,
        'todayTransactions': todayTransactions,
        'todayRevenue': todayRevenue,
        'averageTransaction': totalTransactions > 0 ? totalRevenue / totalTransactions : 0,
      };
    } catch (e) {
      print('❌ Error calculating merchant stats: $e');
      return {
        'totalRevenue': 0.0,
        'totalTransactions': 0,
        'todayTransactions': 0,
        'todayRevenue': 0.0,
        'averageTransaction': 0.0,
      };
    }
  }

  /// Record a payment transaction
  Future<void> recordTransaction({
    required String merchantAddress,
    required String customerAddress,
    required double amount,
    required String currency,
    required String txHash,
    String? notes,
  }) async {
    try {
      await _firestore.collection('transactions').add({
        'merchantAddress': merchantAddress.toLowerCase(),
        'customerAddress': customerAddress.toLowerCase(),
        'amount': amount,
        'currency': currency,
        'txHash': txHash,
        'notes': notes,
        'timestamp': Timestamp.now(),
        'status': 'completed',
      });
      print('✅ Transaction recorded: $amount $currency');
    } catch (e) {
      print('❌ Error recording transaction: $e');
      rethrow;
    }
  }
}
