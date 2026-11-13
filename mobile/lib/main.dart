import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/auth/auth_session_manager.dart';
import 'core/data/app_data_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore persistent authentication session and dynamic real financial data
  await AuthSessionManager.instance.initialize();
  await AppDataRepository.instance.initialize();
  runApp(
    const ProviderScope(
      child: SpendMateApp(),
    ),
  );
}

class SpendMateApp extends StatelessWidget {
  const SpendMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SpendMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
