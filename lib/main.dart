import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Notification Service initialization warning : $e');
  }

  runApp(const ProviderScope(child: RidonovaApp()));
}

class RidonovaApp extends StatelessWidget {
  const RidonovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: MaterialApp(
        title: 'Ridonova - Customer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
// 9638527410