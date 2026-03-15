import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/router_provider.dart';
import 'providers/dashboard_providers.dart';
import 'theme/app_theme.dart';

void main() {
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
