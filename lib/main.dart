import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:monixx/services/smart_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/settings_service.dart';
import 'services/security_service.dart';
import 'services/auth_service.dart';
import 'services/recurring_transaction_service.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Global Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Add crash reporting service like Sentry or Firebase Crashlytics here
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Platform error handling
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // TODO: Add crash reporting service here
    debugPrint('Platform Error: $error');
    return true;
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Initialize smart notifications
    try {
      final smartNotifications = SmartNotificationService();
      await smartNotifications.initialize();
      await smartNotifications.scheduleRecurringReminders();
      await smartNotifications.scheduleSavingsMotivation();
    } catch (e) {
      debugPrint('Smart notifications initialization failed: $e');
    }

    // Initialize notifications
    // final notificationService = NotificationService();
    // await notificationService.initialize();
    // await notificationService.requestPermissions();

    // Process recurring transactions on app start
    final recurringService = RecurringTransactionService();
    await recurringService.processRecurringTransactions();

    // Check for alerts
    await notificationService.checkBudgetAlerts();
    await notificationService.checkGoalMilestones();
    await notificationService.scheduleRecurringReminders();
  } catch (e) {
    debugPrint('Initialization Error: $e');
    // We continue to run the app, the UI will handle the error states
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: const MonixxApp(),
    ),
  );
}

class MonixxApp extends StatefulWidget {
  const MonixxApp({super.key});

  @override
  State<MonixxApp> createState() => _MonixxAppState();
}

class _MonixxAppState extends State<MonixxApp> with WidgetsBindingObserver {
  final SettingsService _settings = SettingsService();
  final SecurityService _security = SecurityService();
  bool _isDarkMode = false;
  bool? _isOnboarded;
  bool _isLocked = true;
  bool _hasPasscode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _hasPasscode) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _loadSettings() async {
    final darkMode = await _settings.getDarkMode();
    final onboarded = await _settings.isOnboarded();
    final passcode = await _security.getPasscode();

    if (mounted) {
      setState(() {
        _isDarkMode = darkMode;
        _isOnboarded = onboarded;
        final hadPasscode = _hasPasscode;
        _hasPasscode = passcode != null;
        // Only lock if passcode was just added or on initial load
        if (!hadPasscode && _hasPasscode) {
          _isLocked = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Update system UI based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Monixx - Financial Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: user == null
          ? const LoginScreen()
          : _isOnboarded == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !_isOnboarded!
          ? OnboardingScreen(
              onComplete: () {
                setState(() => _isOnboarded = true);
              },
            )
          : _isLocked && _hasPasscode
          ? LockScreen(onUnlock: () => setState(() => _isLocked = false))
          : MainNavigation(onThemeChanged: () async => _loadSettings()),
      debugShowCheckedModeBanner: false,
    );
  }
}
