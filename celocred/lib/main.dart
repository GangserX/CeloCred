import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/new_home_screen.dart';
import 'core/services/storage_service.dart';
import 'core/services/firebase_service.dart';
import 'core/providers/wallet_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 Initialize Firebase
  try {
    await FirebaseService.instance.initialize();
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  // 🧹 SECURITY: Clean up old private keys from insecure version
  try {
    await StorageService().deleteOldPrivateKeys();
    print('✅ Security cleanup complete');
  } catch (e) {
    print('⚠️ Security cleanup warning: $e');
  }
  
  // 💼 Initialize wallet provider
  await WalletProvider.instance.initialize();
  
  runApp(const CeloCredApp());
}

class CeloCredApp extends StatelessWidget {
  const CeloCredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: WalletProvider.instance,
      child: MaterialApp(
        title: 'CeloCred',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const NewHomeScreen(),
      ),
    );
  }
}
