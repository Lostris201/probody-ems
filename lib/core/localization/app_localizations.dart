import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Helper method to get localized strings
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Shorthand accessor for localization strings
  String get(String key) => translate(key);

  // Helper method to format dates according to the locale
  String formatDate(DateTime date, {String? pattern}) {
    final DateFormat formatter = pattern != null
        ? DateFormat(pattern, locale.languageCode)
        : DateFormat.yMMMd(locale.languageCode);
    return formatter.format(date);
  }

  // Helper method to format times according to the locale
  String formatTime(DateTime time) {
    final DateFormat formatter = DateFormat.Hm(locale.languageCode);
    return formatter.format(time);
  }

  // Cached localized strings
  static final Map<String, String> _localizedStrings = {
    // Common
    'app_name': 'Probody EMS',
    'ok': 'OK',
    'cancel': 'Cancel',
    'next': 'Next',
    'back': 'Back',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'warning': 'Warning',
    'info': 'Information',
    'retry': 'Retry',
    
    // Auth
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'forgot_password': 'Forgot Password?',
    'reset_password': 'Reset Password',
    'logout': 'Logout',
    'create_account': 'Create Account',
    'already_have_account': 'Already have an account?',
    'dont_have_account': 'Don\'t have an account?',
    'auth_error': 'Authentication Error',
    'invalid_email': 'Please enter a valid email address',
    'password_too_short': 'Password must be at least 6 characters',
    'passwords_dont_match': 'Passwords do not match',
    'login_success': 'Login successful',
    'register_success': 'Registration successful',
    'logout_success': 'Logout successful',
    'reset_password_instructions': 'Enter your email address to receive password reset instructions',
    'reset_password_sent': 'Password reset email sent',
    'first_name': 'First Name',
    'last_name': 'Last Name',
    'phone_number': 'Phone Number',
    
    // Home
    'home': 'Home',
    'welcome': 'Welcome',
    'welcome_back': 'Welcome back',
    'recent_programs': 'Recent Programs',
    'view_all': 'View All',
    'connected_devices': 'Connected Devices',
    'no_connected_devices': 'No devices connected',
    'connect_device': 'Connect Device',
    'training_history': 'Training History',
    'no_training_history': 'No training history yet',
    'ai_assistant': 'AI Sport Assistant',
    'ai_chat_title': 'Sports Assistant',
    'ask_ai': 'Ask your sports questions...',
    
    // Programs
    'programs': 'Programs',
    'favorites': 'Favorites',
    'search_programs': 'Search programs...',
    'no_programs_found': 'No programs found',
    'no_favorites': 'No favorite programs',
    'add_to_favorites': 'Add to favorites',
    'remove_from_favorites': 'Remove from favorites',
    'program_details': 'Program Details',
    'start_program': 'Start Program',
    'program_duration': 'Duration',
    'program_intensity': 'Intensity',
    'program_type': 'Type',
    'program_target_zones': 'Target Zones',
    'minutes': 'minutes',
    'seconds': 'seconds',
    'program_min': 'min',
    'program_sec': 'sec',
    
    // Training
    'training': 'Training',
    'start': 'Start',
    'pause': 'Pause',
    'resume': 'Resume',
    'stop': 'Stop',
    'intensity': 'Intensity',
    'duration': 'Duration',
    'remaining_time': 'Remaining Time',
    'training_complete': 'Training Complete',
    'training_paused': 'Training Paused',
    'training_stopped': 'Training Stopped',
    'save_training': 'Save Training',
    'discard_training': 'Discard Training',
    'training_saved': 'Training saved to history',
    'training_discarded': 'Training discarded',
    'adjust_intensity': 'Adjust Intensity',
    'front_view': 'Front',
    'back_view': 'Back',
    'training_summary': 'Training Summary',
    'total_duration': 'Total Duration',
    'average_intensity': 'Average Intensity',
    'calories_burned': 'Calories Burned',
    'targeted_muscles': 'Targeted Muscles',
    
    // Devices
    'devices': 'Devices',
    'device_management': 'Device Management',
    'add_device': 'Add Device',
    'scan_for_devices': 'Scan for Devices',
    'scanning': 'Scanning...',
    'no_devices_found': 'No devices found',
    'connect': 'Connect',
    'disconnect': 'Disconnect',
    'connected': 'Connected',
    'disconnected': 'Disconnected',
    'connecting': 'Connecting...',
    'disconnecting': 'Disconnecting...',
    'device_name': 'Device Name',
    'rename_device': 'Rename Device',
    'delete_device': 'Delete Device',
    'confirm_delete_device': 'Are you sure you want to delete this device?',
    'device_deleted': 'Device deleted',
    'device_renamed': 'Device renamed',
    'my_devices': 'My Devices',
    'available_devices': 'Available Devices',
    'battery_level': 'Battery Level',
    'last_connected': 'Last Connected',
    'firmware_version': 'Firmware Version',
    'connection_failed': 'Connection failed',
    'bluetooth_disabled': 'Bluetooth is disabled',
    'enable_bluetooth': 'Please enable Bluetooth to connect to devices',
    'permission_required': 'Permission Required',
    'location_permission_message': 'Location permission is required to scan for devices',
    
    // Account
    'account': 'Account',
    'profile': 'Profile',
    'settings': 'Settings',
    'personal_info': 'Personal Information',
    'update_profile': 'Update Profile',
    'change_password': 'Change Password',
    'notifications': 'Notifications',
    'language': 'Language',
    'theme': 'Theme',
    'dark_mode': 'Dark Mode',
    'light_mode': 'Light Mode',
    'system_default': 'System Default',
    'profile_updated': 'Profile updated successfully',
    'password_changed': 'Password changed successfully',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'password_rules': 'Password must be at least 6 characters',
    
    // Muscle Zones
    'zone_abs': 'Abdominals',
    'zone_chest': 'Chest',
    'zone_back': 'Back',
    'zone_shoulders': 'Shoulders',
    'zone_biceps': 'Biceps',
    'zone_triceps': 'Triceps',
    'zone_forearms': 'Forearms',
    'zone_glutes': 'Glutes',
    'zone_quads': 'Quadriceps',
    'zone_hamstrings': 'Hamstrings',
    'zone_calves': 'Calves',
    'zone_lower_back': 'Lower Back',
    'zone_traps': 'Trapezius',
    'zone_lats': 'Latissimus Dorsi',
    
    // AI Chat
    'ai_chat': 'AI Sports Assistant',
    'chat_placeholder': 'Ask about training, recovery, or EMS...',
    'ai_typing': 'AI is typing...',
    'ai_suggestions': 'Suggestions',
    'suggestion_benefits': 'What are the benefits of EMS training?',
    'suggestion_frequency': 'How often should I do EMS training?',
    'suggestion_muscles': 'Which muscle groups should I target?',
    'suggestion_safety': 'Is EMS training safe?',
    'suggestion_preparation': 'How should I prepare for an EMS session?',
    'suggestion_recovery': 'What\'s the best way to recover after EMS?',
    'suggestion_results': 'When will I see results from EMS training?',
    'ai_welcome': 'Hello! I\'m your EMS training assistant. How can I help you today?',
    
    // Errors
    'network_error': 'Network Error',
    'connection_error': 'Connection Error',
    'unknown_error': 'Unknown Error',
    'try_again': 'Please try again',
    'data_fetch_error': 'Failed to fetch data',
    'data_save_error': 'Failed to save data',
    'required_field': 'This field is required',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr', 'de', 'fr', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}