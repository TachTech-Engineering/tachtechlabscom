import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/matrix_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AttckDashboardApp(),
    ),
  );
}

class AttckDashboardApp extends StatelessWidget {
  const AttckDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATT&CK Coverage Dashboard',
      theme: AppTheme.lightTheme,
      home: const MatrixPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
