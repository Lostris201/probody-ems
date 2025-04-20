import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:probody_ems/core/localization/app_localizations.dart';
import 'package:probody_ems/core/theme/app_theme.dart';
import 'package:probody_ems/presentation/screens/auth/login_screen.dart';
import 'package:probody_ems/presentation/screens/home/home_screen.dart';
import 'package:probody_ems/presentation/screens/auth/register_screen.dart';
import 'package:probody_ems/presentation/screens/programs/program_selection_screen.dart';
import 'package:probody_ems/presentation/screens/training/training_screen.dart';
import 'package:probody_ems/presentation/screens/devices/device_management_screen.dart';
import 'package:probody_ems/presentation/screens/chat/ai_chat_screen.dart';

class ProbodyEmsApp extends StatelessWidget {
  const ProbodyEmsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Probody EMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('tr', ''), // Turkish
        Locale('de', ''), // German
      ],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/programs': (context) => const ProgramSelectionScreen(),
        '/training': (context) => const TrainingScreen(),
        '/devices': (context) => const DeviceManagementScreen(),
        '/ai_chat': (context) => const AiChatScreen(),
      },
    );
  }
}