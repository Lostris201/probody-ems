import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIChatService {
  // API endpoint configuration - in real implementation, this would 
  // connect to a backend with proper API key management
  final String _baseUrl = 'https://api.example.com/ai-chat';
  
  // Store conversation history
  final List<Map<String, dynamic>> _conversationHistory = [];
  
  // Maximum number of messages to keep in history
  final int _maxHistoryLength = 20;
  
  // Cache key for storing conversation history
  static const String _cacheKey = 'ai_chat_history';
  
  AIChatService() {
    _loadConversationHistory();
  }
  
  // Load conversation history from local storage
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_cacheKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _conversationHistory.clear();
        _conversationHistory.addAll(
          decoded.map((item) => Map<String, dynamic>.from(item)).toList()
        );
      }
    } catch (e) {
      print('Error loading conversation history: $e');
    }
  }
  
  // Save conversation history to local storage
  Future<void> _saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_conversationHistory);
      await prefs.setString(_cacheKey, historyJson);
    } catch (e) {
      print('Error saving conversation history: $e');
    }
  }
  
  // Add a message to the conversation history
  void _addToHistory(Map<String, dynamic> message) {
    _conversationHistory.add(message);
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }
    _saveConversationHistory();
  }
  
  // Get the conversation history
  List<Map<String, dynamic>> getConversationHistory() {
    return List.from(_conversationHistory);
  }
  
  // Clear conversation history
  Future<void> clearConversationHistory() async {
    _conversationHistory.clear();
    await _saveConversationHistory();
  }
  
  // Send message to AI and get response
  // In a real implementation, this would connect to an AI service API
  Future<String> sendMessage(String message, String userId) async {
    // Add user message to history
    _addToHistory({
      'role': 'user',
      'content': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    try {
      // Simulate API call - in real implementation, this would be an actual API call
      final response = await _simulateAIResponse(message);
      
      // Add AI response to history
      _addToHistory({
        'role': 'ai',
        'content': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      return response;
    } catch (e) {
      print('Error getting AI response: $e');
      return 'Sorry, I encountered an error processing your request. Please try again later.';
    }
  }
  
  // Simulate AI response - this would be replaced with actual API call in production
  Future<String> _simulateAIResponse(String message) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    message = message.toLowerCase();
    
    // Basic response logic based on keywords
    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! How can I help you with your EMS training today?';
    } else if (message.contains('benefit') || message.contains('advantage')) {
      return 'EMS training offers several benefits including: improved muscle strength, enhanced recovery, time efficiency, and targeted muscle activation. Regular sessions can complement your existing workout routine.';
    } else if (message.contains('frequency') || message.contains('how often')) {
      return 'For optimal results, most experts recommend 1-2 EMS sessions per week with at least 48 hours of recovery between sessions. Your body needs time to recover and adapt to the stimulus.';
    } else if (message.contains('muscle') || message.contains('target')) {
      return 'EMS can effectively target various muscle groups including abs, glutes, quads, hamstrings, calves, back, chest, and arms. The Probody app allows you to select specific muscle zones for each training program.';
    } else if (message.contains('safe') || message.contains('danger')) {
      return 'EMS training is generally safe when used properly. Always follow the instructions, start with lower intensity, and gradually increase. Avoid using EMS if you have pacemakers, electronic implants, epilepsy, or during pregnancy.';
    } else if (message.contains('prepare') || message.contains('before')) {
      return 'Before an EMS session: stay hydrated, avoid heavy meals, wear comfortable clothing, and ensure proper electrode placement. Make sure your device is properly charged and connected.';
    } else if (message.contains('after') || message.contains('recovery')) {
      return 'After an EMS session: hydrate well, consider light stretching, allow 48 hours for muscle recovery, and maintain proper nutrition with adequate protein intake to support muscle recovery.';
    } else if (message.contains('result') || message.contains('expect')) {
      return 'Results vary by individual, but many users report feeling muscle activation immediately. Noticeable strength and endurance improvements typically occur after 4-6 weeks of consistent training. Track your progress in the app!';
    } else if (message.contains('device') || message.contains('connection')) {
      return 'To connect your device, go to the Device Management screen, enable Bluetooth on your phone, and select your device from the available list. Make sure your device is charged and within range.';
    } else {
      return 'Thanks for your question about EMS training. For more specific guidance, please try asking about benefits, frequency, muscle targeting, safety, preparation, recovery, or expected results.';
    }
  }
}