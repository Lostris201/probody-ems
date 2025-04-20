import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/device_repository.dart';
import 'data/repositories/program_repository.dart';
import 'data/repositories/user_repository.dart';
import 'firebase_options.dart';
import 'presentation/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/bluetooth_service.dart';
import 'utils/localization/app_localizations.dart';

/// Main entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Get shared preferences instance
  final prefs = await SharedPreferences.getInstance();
  
  // Set preferred device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp(prefs: prefs));
}

/// Root application widget
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<UserRepository>(
          create: (_) => UserRepository(),
        ),
        Provider<ProgramRepository>(
          create: (_) => ProgramRepository(),
        ),
        Provider<DeviceRepository>(
          create: (_) => DeviceRepository(),
        ),
        Provider<BluetoothService>(
          create: (_) => BluetoothService(prefs),
        ),
        // Add other providers as needed
      ],
      child: MaterialApp(
        title: 'ProBody EMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        themeMode: ThemeMode.light, // Default to light theme
        
        // Initialize routes
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          // Handle route based on settings.name
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(
                builder: (_) => const SplashScreen(),
              );
            case AppRoutes.onboarding:
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
            case AppRoutes.login:
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );
            case AppRoutes.register:
              return MaterialPageRoute(
                builder: (_) => const RegisterScreen(),
              );
            case AppRoutes.home:
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
            case AppRoutes.profile:
              return MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              );
            case AppRoutes.programSelection:
              return MaterialPageRoute(
                builder: (_) => const ProgramSelectionScreen(),
              );
            case AppRoutes.programDetail:
              final programId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ProgramDetailScreen(programId: programId),
              );
            case AppRoutes.training:
              final programId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => TrainingScreen(programId: programId),
              );
            case AppRoutes.deviceManagement:
              return MaterialPageRoute(
                builder: (_) => const DeviceManagementScreen(),
              );
            case AppRoutes.aiChat:
              return MaterialPageRoute(
                builder: (_) => const AiChatScreen(),
              );
            default:
              // If route not found, redirect to home
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
          }
        },
        
        // Localization setup
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('tr', ''), // Turkish
          // Add more locales as needed
        ],
      ),
    );
  }
}

// Placeholder screens until actual implementations are imported
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Onboarding')));
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login')));
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Register')));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile')));
}

class ProgramDetailScreen extends StatelessWidget {
  final String programId;
  const ProgramDetailScreen({Key? key, required this.programId}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Program Detail: $programId')));
}

class TrainingScreen extends StatelessWidget {
  final String programId;
  const TrainingScreen({Key? key, required this.programId}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Training: $programId')));
}