import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIChatService {
  // API endpoint (replace with your actual endpoint)
  static const String API_ENDPOINT = "https://api.probody-ems.com/ai-chat";
  
  // Cache key for storing chat history
  static const String CHAT_HISTORY_KEY = "ai_chat_history";
  
  // Maximum number of messages to store in history
  static const int MAX_HISTORY_LENGTH = 50;
  
  // Message model for chat
  static class ChatMessage {
    final String text;
    final bool isUser;
    final DateTime timestamp;
    
    ChatMessage({
      required this.text,
      required this.isUser,
      required this.timestamp,
    });
    
    Map<String, dynamic> toJson() {
      return {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };
    }
    
    factory ChatMessage.fromJson(Map<String, dynamic> json) {
      return ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
      );
    }
  }
  
  // Get chat history from local storage
  Future<List<ChatMessage>> getChatHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? historyJson = prefs.getString(CHAT_HISTORY_KEY);
      
      if (historyJson == null) {
        return [];
      }
      
      List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      print('Error retrieving chat history: $e');
      return [];
    }
  }
  
  // Save chat history to local storage
  Future<void> saveChatHistory(List<ChatMessage> history) async {
    try {
      // Limit the history length
      if (history.length > MAX_HISTORY_LENGTH) {
        history = history.sublist(history.length - MAX_HISTORY_LENGTH);
      }
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> historyJson = history.map((msg) => msg.toJson()).toList();
      await prefs.setString(CHAT_HISTORY_KEY, jsonEncode(historyJson));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }
  
  // Add a new message to history
  Future<void> addMessageToHistory(ChatMessage message) async {
    List<ChatMessage> history = await getChatHistory();
    history.add(message);
    await saveChatHistory(history);
  }
  
  // Clear chat history
  Future<void> clearChatHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(CHAT_HISTORY_KEY);
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }
  
  // Get AI response for a user message
  Future<String> getAIResponse(String userMessage, {List<ChatMessage>? context}) async {
    try {
      // If we're in demo mode or API isn't available, use mockResponse
      if (!await _isApiAvailable()) {
        return await _mockResponse(userMessage);
      }
      
      // Prepare context from previous messages if provided
      List<Map<String, dynamic>> messageContext = [];
      if (context != null && context.isNotEmpty) {
        // Only use the last 10 messages for context
        List<ChatMessage> recentContext = context.length > 10 
            ? context.sublist(context.length - 10) 
            : context;
            
        for (ChatMessage msg in recentContext) {
          messageContext.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text
          });
        }
      }
      
      // Add current user message
      messageContext.add({
        'role': 'user',
        'content': userMessage
      });
      
      // Make API request
      final response = await http.post(
        Uri.parse(API_ENDPOINT),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': messageContext,
        }),
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return data['response'] ?? "I'm sorry, I couldn't process your request.";
      } else {
        print('API Error: ${response.statusCode}');
        return "I'm sorry, I'm having trouble connecting to my knowledge base right now.";
      }
    } catch (e) {
      print('Error getting AI response: $e');
      return "I'm sorry, there was an error processing your request.";
    }
  }
  
  // Check if API is available
  Future<bool> _isApiAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('${API_ENDPOINT}/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Mock response for demo mode or when API is unavailable
  Future<String> _mockResponse(String userMessage) async {
    // Add a delay to simulate API call
    await Future.delayed(Duration(milliseconds: 500 + (userMessage.length * 10)));
    
    // Convert to lowercase for easier matching
    String message = userMessage.toLowerCase();
    
    // Basic pattern matching for common EMS questions
    if (message.contains('benefit') || message.contains('advantage')) {
      return "EMS training can offer several benefits including: strengthening muscles, improving endurance, supporting rehabilitation after injuries, and potentially saving time compared to conventional training. It's especially effective for deep muscle activation that's harder to target with conventional workouts.";
    } else if (message.contains('how often') || message.contains('frequency')) {
      return "For beginners, 1-2 EMS sessions per week is recommended to allow your body to adapt. More experienced users can do 2-3 sessions weekly. Always allow at least 48 hours between sessions for muscle recovery. Remember that EMS is intense and your body needs time to recover and adapt.";
    } else if (message.contains('safe') || message.contains('risk')) {
      return "EMS training is generally safe when used correctly, but should be avoided by people with pacemakers, epilepsy, cancer, cardiovascular issues, or during pregnancy. Always consult with a healthcare provider before starting EMS training, especially if you have any medical conditions.";
    } else if (message.contains('intensity') || message.contains('level')) {
      return "Start with low intensity (30-40% of maximum) and gradually increase as your body adapts. The right intensity should feel challenging but not painful. You should feel a strong contraction but still be able to maintain proper form and breathing. Everyone's tolerance differs, so listen to your body.";
    } else if (message.contains('prepare') || message.contains('before session')) {
      return "Before an EMS session: stay hydrated, avoid heavy meals 2-3 hours before, wear comfortable clothing, avoid alcohol, ensure electrodes are properly placed, and start with a proper warm-up. Proper preparation enhances the effectiveness and safety of your training.";
    } else if (message.contains('muscle') || message.contains('target') || message.contains('zone')) {
      return "The ProBody EMS system can target major muscle groups including: chest, back, shoulders, biceps, triceps, abs, obliques, lower back, glutes, quadriceps, hamstrings, and calves. The app allows you to select specific muscle zones and control the intensity for each zone independently.";
    } else if (message.contains('recover') || message.contains('after session')) {
      return "After an EMS session: hydrate well, have a protein-rich meal or shake within 30-45 minutes, stretch gently, consider light active recovery, use foam rolling if needed, and ensure adequate sleep. Good recovery practices enhance your results and reduce soreness.";
    } else if (message.contains('result') || message.contains('effective') || message.contains('work')) {
      return "EMS results vary between individuals. Most users notice improved muscle tone within 4-6 weeks of consistent training. For strength gains, it typically takes 6-8 weeks. To maximize results, combine EMS with regular exercise and proper nutrition. Consistency is key to seeing meaningful changes.";
    } else if (message.contains('hello') || message.contains('hi ') || message.contains('hey')) {
      return "Hello! I'm your ProBody EMS training assistant. How can I help you with your EMS training today?";
    } else {
      return "I understand you're asking about EMS training. Could you clarify what specific aspect of EMS you'd like information about? I can help with benefits, safety, preparation, muscle targeting, recommended frequency, or recovery strategies.";
    }
  }
  
  // Get personalized suggestions based on user profile and training history
  Future<List<String>> getPersonalizedSuggestions() async {
    // In a real implementation, this would analyze user data
    // For now, we'll return generic suggestions
    return [
      "How can I maximize my EMS results?",
      "What's the ideal recovery time between sessions?",
      "Can I combine EMS with my regular workouts?",
      "What intensity level is right for beginners?",
      "How should I prepare for an EMS session?",
    ];
  }
}