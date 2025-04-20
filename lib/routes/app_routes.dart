import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/chat/ai_chat_screen.dart';
import '../presentation/screens/devices/device_management_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/programs/program_detail_screen.dart';
import '../presentation/screens/programs/program_selection_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/training/training_screen.dart';

/// Class that defines all routes in the application
class AppRoutes {
  // Route names as constants
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String programSelection = '/programs';
  static const String programDetail = '/program-detail';
  static const String training = '/training';
  static const String deviceManagement = '/devices';
  static const String aiChat = '/ai-chat';

  /// Map of all routes with their corresponding widget builders
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const HomeScreen(),
      profile: (context) => const ProfileScreen(),
      programSelection: (context) => const ProgramSelectionScreen(),
      programDetail: (context) => ProgramDetailScreen(
        programId: ModalRoute.of(context)!.settings.arguments as String,
      ),
      training: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return TrainingScreen(
          programId: args['programId'] as String,
          deviceId: args['deviceId'] as String?,
        );
      },
      deviceManagement: (context) => const DeviceManagementScreen(),
      aiChat: (context) => const AiChatScreen(),
    };
  }

  /// Handle unknown routes by redirecting to home
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const HomeScreen(),
    );
  }
}