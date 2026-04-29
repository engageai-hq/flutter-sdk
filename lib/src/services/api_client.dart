import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/engageai_config.dart';
import '../models/agent_action.dart';
import '../models/user_context.dart';

/// HTTP client for communicating with the EngageAI backend.
class EngageAIApiClient {
  final EngageAIConfig config;
  final http.Client _httpClient;

  EngageAIApiClient({required this.config, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  String get _baseUrl => config.serverUrl.replaceAll(RegExp(r'/$'), '');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (config.apiKey != null) 'X-EngageAI-Key': config.apiKey!,
      };

  /// Register the app manifest with the server.
  /// Throws [StateError] on failure.
  /// Returns the custom character URL for enterprise plans, or null for default character.
  Future<String?> registerManifest(Map<String, dynamic> manifest) async {
    final response = await _post('/api/v1/register', {
      'manifest': manifest,
    });
    if (response['success'] != true) {
      throw StateError('Failed to register manifest with EngageAI server');
    }
    return response['character_url'] as String?;
  }

  /// Send a chat message and get the agent's response.
  Future<ChatApiResponse> sendMessage({
    required String sessionId,
    required String message,
    EngageUserContext? userContext,
  }) async {
    final body = {
      'session_id': sessionId,
      'app_id': config.appId,
      'message': message,
      if (userContext != null) 'user_context': userContext.toJson(),
    };

    final response = await _post('/api/v1/chat', body);
    return ChatApiResponse.fromJson(response);
  }

  /// Send function execution results back to the agent.
  Future<ChatApiResponse> sendFunctionResults({
    required String sessionId,
    required List<Map<String, dynamic>> results,
  }) async {
    final body = {
      'session_id': sessionId,
      'app_id': config.appId,
      'results': results,
    };

    final response = await _post('/api/v1/results', body);
    return ChatApiResponse.fromJson(response);
  }

  /// Confirm or deny a pending action.
  Future<ChatApiResponse> sendConfirmation({
    required String sessionId,
    required bool confirmed,
    String? callId,
  }) async {
    final body = {
      'session_id': sessionId,
      'app_id': config.appId,
      'confirmed': confirmed,
      if (callId != null) 'call_id': callId,
    };

    final response = await _post('/api/v1/confirm', body);
    return ChatApiResponse.fromJson(response);
  }

  /// Generic POST request.
  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');

    if (config.debug) {
      print('[EngageAI] POST $path');
      print('[EngageAI] Body: ${jsonEncode(body)}');
    }

    final response = await _httpClient
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(Duration(seconds: config.timeoutSeconds));

    if (config.debug) {
      print('[EngageAI] Response ${response.statusCode}: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw EngageAIApiException(
        statusCode: response.statusCode,
        message: response.body,
        path: path,
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Parsed response from the chat API.
class ChatApiResponse {
  final String sessionId;
  final AgentAction action;
  final int conversationLength;

  const ChatApiResponse({
    required this.sessionId,
    required this.action,
    required this.conversationLength,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      sessionId: json['session_id'] as String,
      action: AgentAction.fromJson(json['action'] as Map<String, dynamic>),
      conversationLength: json['conversation_length'] as int? ?? 0,
    );
  }
}

/// Exception thrown by the API client.
class EngageAIApiException implements Exception {
  final int statusCode;
  final String message;
  final String path;

  const EngageAIApiException({
    required this.statusCode,
    required this.message,
    required this.path,
  });

  @override
  String toString() =>
      'EngageAIApiException($statusCode on $path): $message';
}
