import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/engageai_config.dart';
import '../models/user_context.dart';

/// Connects to the streaming chat endpoint and delivers text token by token.
class EngageStreamingService {
  final EngageAIConfig config;
  final http.Client _httpClient;

  EngageStreamingService({required this.config, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  String get _baseUrl => config.serverUrl.replaceAll(RegExp(r'/$'), '');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (config.apiKey != null) 'X-EngageAI-Key': config.apiKey!,
      };

  /// Send a message and receive a stream of text deltas.
  ///
  /// Yields [StreamEvent] objects as they arrive from the server.
  Stream<StreamEvent> streamMessage({
    required String sessionId,
    required String message,
    EngageUserContext? userContext,
  }) async* {
    final body = jsonEncode({
      'session_id': sessionId,
      'app_id': config.appId,
      'message': message,
      if (userContext != null) 'user_context': userContext.toJson(),
    });

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/api/v1/chat/stream'),
      );
      _headers.forEach((k, v) => request.headers[k] = v);
      request.body = body;

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        yield StreamEvent(
          type: StreamEventType.error,
          data: 'Server error: ${response.statusCode}',
        );
        return;
      }

      // Parse SSE stream
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // SSE events are separated by double newlines
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventStr = buffer.substring(0, eventEnd);
          buffer = buffer.substring(eventEnd + 2);

          // Parse SSE event
          for (final line in eventStr.split('\n')) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              try {
                final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                final event = _parseEvent(data);
                if (event != null) {
                  yield event;
                }
              } catch (e) {
                if (config.debug) {
                  print('[EngageAI Stream] Parse error: $e for: $jsonStr');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      yield StreamEvent(
        type: StreamEventType.error,
        data: e.toString(),
      );
    }
  }

  StreamEvent? _parseEvent(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'stream_start':
        return StreamEvent(
          type: StreamEventType.streamStart,
          sessionId: data['session_id'] as String?,
        );

      case 'text_delta':
        return StreamEvent(
          type: StreamEventType.textDelta,
          data: data['text'] as String? ?? '',
        );

      case 'tool_start':
        return StreamEvent(
          type: StreamEventType.toolStart,
          data: data['tool_name'] as String? ?? '',
          toolId: data['tool_id'] as String?,
        );

      case 'tool_delta':
        return StreamEvent(
          type: StreamEventType.toolDelta,
          data: data['partial'] as String? ?? '',
        );

      case 'stop':
        return StreamEvent(
          type: StreamEventType.stop,
          data: data['reason'] as String? ?? '',
        );

      case 'stream_end':
        return StreamEvent(
          type: StreamEventType.streamEnd,
          data: data['full_text'] as String? ?? '',
          actionType: data['action_type'] as String? ?? 'respond',
          functionCalls: List<Map<String, dynamic>>.from(
            data['function_calls'] ?? [],
          ),
          requiresConfirmation: data['requires_confirmation'] as bool? ?? false,
        );

      case 'error':
        return StreamEvent(
          type: StreamEventType.error,
          data: data['message'] as String? ?? 'Unknown error',
        );

      default:
        return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

enum StreamEventType {
  streamStart,
  textDelta,
  toolStart,
  toolDelta,
  stop,
  streamEnd,
  error,
}

class StreamEvent {
  final StreamEventType type;
  final String? data;
  final String? sessionId;
  final String? toolId;
  final String? actionType;
  final List<Map<String, dynamic>>? functionCalls;
  final bool requiresConfirmation;

  const StreamEvent({
    required this.type,
    this.data,
    this.sessionId,
    this.toolId,
    this.actionType,
    this.functionCalls,
    this.requiresConfirmation = false,
  });
}
