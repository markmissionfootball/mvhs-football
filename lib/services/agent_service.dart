import 'package:cloud_functions/cloud_functions.dart';

class AgentService {
  Future<String> sendMessage({
    required String playerId,
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('agentChat');
      final result = await callable.call({
        'playerId': playerId,
        'message': message,
        'conversationHistory': conversationHistory,
      });
      return result.data['response'] as String;
    } catch (e) {
      return "I'm not connected to the backend yet. Once deployed, I'll be able to help with workouts, stats, recruiting, and more. Try asking me about your schedule or training!";
    }
  }
}
