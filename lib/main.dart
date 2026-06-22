import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/task_storage_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await TaskStorageService.init();
  await NotificationService().init();
  
  runApp(const LipiApp());
}

class LipiApp extends StatefulWidget {
  const LipiApp({super.key});

  @override
  State<LipiApp> createState() => _LipiAppState();
}

class _LipiAppState extends State<LipiApp> {
  // Global state for theme mode within this interactive demo
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        // If system, toggle based on current platform brightness
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lipi',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: LipiHomeScreen(
        isDarkMode: _themeMode == ThemeMode.dark ||
            (_themeMode == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark),
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
