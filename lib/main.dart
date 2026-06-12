import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/brushing_provider.dart';
import 'providers/music_provider.dart';
import 'providers/child_provider.dart';
import 'providers/rewards_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/add_child_screen.dart';
import 'screens/brushing_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };
  
  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack: $stack');
    return true;
  };
  
  runApp(const TodoosApp());
}

class TodoosApp extends StatefulWidget {
  const TodoosApp({super.key});

  @override
  State<TodoosApp> createState() => _TodoosAppState();
}

class _TodoosAppState extends State<TodoosApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = BrushingProvider();
            // Load settings asynchronously without blocking
            provider.loadSettings().catchError((error) {
              debugPrint('Error initializing BrushingProvider: $error');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => MusicProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ChildProvider();
            // Load children and history asynchronously
            provider.loadData().catchError((error) {
              debugPrint('Error initializing ChildProvider: $error');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = RewardsProvider();
            provider.loadData().catchError((error) {
              debugPrint('Error initializing RewardsProvider: $error');
            });
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'todoos - Brushing Helper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/add-child': (context) => const AddChildScreen(),
          '/brushing': (context) => const BrushingScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
