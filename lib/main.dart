import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordle_clone/services/word_checker.dart';
import 'pages/homepage/home.dart';
import 'providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before using rootBundle
  // Initialize timezone data FIRST
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Dubai')); 
  await WordLoader.loadWords(); // Load words here
  await NotificationService().init(); // Initialize notification service
  await NotificationService()
      .scheduleDailyNotifications(); // Schedule notifications
  await dotenv.load(); // Load environment variables
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: const Color.fromARGB(255, 255, 255, 255),
          displayColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white70),
          trackColor: WidgetStateProperty.all(Colors.lightGreenAccent),
        ),
      ),
      themeMode: themeMode,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
