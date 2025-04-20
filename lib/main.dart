import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:probody_ems/presentation/navigation/app_router.dart';
import 'package:probody_ems/presentation/theme/app_theme.dart';
import 'package:probody_ems/services/app_localization.dart';
import 'package:provider/provider.dart';
import 'package:probody_ems/data/repositories/user_repository.dart';
import 'package:probody_ems/data/repositories/program_repository.dart';
import 'package:probody_ems/data/repositories/device_repository.dart';
import 'package:probody_ems/services/bluetooth_service.dart';
import 'package:probody_ems/services/ai_chat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _appRouter = AppRouter();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
          create: (_) => BluetoothService(),
        ),
        Provider<AIChatService>(
          create: (_) => AIChatService(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Probody EMS',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('tr', ''),
        ],
        routerDelegate: _appRouter.delegate(),
        routeInformationParser: _appRouter.defaultRouteParser(),
      ),
    );
  }
}