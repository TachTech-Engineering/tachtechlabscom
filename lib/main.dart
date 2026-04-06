import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/router_provider.dart';
import 'providers/dashboard_providers.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously - this gives us a Firebase Auth token
  // that Cloud Functions can verify without needing allUsers IAM
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Signed in anonymously: ${userCredential.user?.uid}');
  } catch (e) {
    debugPrint('Anonymous sign-in failed: $e');
    // App continues without auth - will fall back to public endpoints if available
  }

  runApp(
    const ProviderScope(
      child: AttckDashboardApp(),
    ),
  );
}

class AttckDashboardApp extends ConsumerWidget {
  const AttckDashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ATT&CK Coverage Dashboard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
