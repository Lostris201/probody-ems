import 'package:flutter/material.dart';

/// NavigationService provides a centralized way to handle navigation in the app.
/// It uses a GlobalKey for the navigator state, allowing navigation from anywhere
/// without requiring a BuildContext.
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Navigate to a named route with optional arguments
  Future<dynamic> navigateTo(String routeName, {Map<String, dynamic>? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  /// Replace current route with a new named route and optional arguments
  Future<dynamic> replaceTo(String routeName, {Map<String, dynamic>? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName, 
      arguments: arguments
    );
  }
  
  /// Navigate to a named route and remove all previous routes
  Future<dynamic> navigateToAndClearStack(String routeName, {Map<String, dynamic>? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (_) => false,
      arguments: arguments
    );
  }
  
  /// Go back to the previous route
  void goBack() {
    return navigatorKey.currentState!.pop();
  }
  
  /// Go back to the previous route with a result
  void goBackWithResult(dynamic result) {
    return navigatorKey.currentState!.pop(result);
  }
  
  /// Go back multiple times
  void goBackMultiple(int times) {
    int count = 0;
    navigatorKey.currentState!.popUntil((_) => count++ >= times);
  }
  
  /// Go back until a specific route
  void goBackUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }
}