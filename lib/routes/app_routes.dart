/// Class containing all application route paths
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();
  
  /// Splash screen
  static const String splash = '/';
  
  /// Onboarding screens
  static const String onboarding = '/onboarding';
  
  /// Authentication screens
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  /// Main screens
  static const String home = '/home';
  static const String profile = '/profile';
  
  /// Program related screens
  static const String programSelection = '/programs';
  static const String programDetail = '/program/detail';
  static const String training = '/training';
  static const String trainingHistory = '/training/history';
  
  /// Device related screens
  static const String deviceManagement = '/devices';
  
  /// Settings screens
  static const String settings = '/settings';
  
  /// AI related screens
  static const String aiChat = '/ai-chat';
}