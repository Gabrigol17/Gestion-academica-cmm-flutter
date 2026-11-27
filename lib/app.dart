import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

class MyApp extends StatelessWidget {
  final ApiClient apiClient;

  const MyApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Académica CMM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomePage(apiClient: apiClient),
    );
  }
}
