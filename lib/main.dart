import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:probody_ems/presentation/app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:probody_ems/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:probody_ems/data/repositories/user_repository.dart';
import 'package:probody_ems/data/repositories/program_repository.dart';
import 'package:probody_ems/data/repositories/device_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize repositories
  final userRepository = UserRepository();
  final programRepository = ProgramRepository();
  final deviceRepository = DeviceRepository();
  
  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<UserRepository>.value(value: userRepository),
        Provider<ProgramRepository>.value(value: programRepository),
        Provider<DeviceRepository>.value(value: deviceRepository),
        Provider<SharedPreferences>.value(value: sharedPreferences),
      ],
      child: const ProbodyEmsApp(),
    ),
  );
}