import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/engageai_config.dart';

/// Handles voice recording, speech-to-text, and text-to-speech audio playback.
///
/// Uses the EngageAI backend which proxies to OpenAI Whisper and TTS.
class EngageVoiceService {
  final EngageAIConfig config;
  final http.Client _httpClient;

  /// Current TTS voice (nova, alloy, echo, fable, onyx, shimmer)
  String voice;

  /// Callback when transcription is ready
  void Function(String text)? onTranscription;

  /// Callback when audio response is ready (base64 mp3)
  void Function(Uint8List audioBytes)? onAudioResponse;

  /// Callback for errors
  void Function(String error)? onError;

  EngageVoiceService({
    required this.config,
    this.voice = 'nova',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  String get _baseUrl => config.serverUrl.replaceAll(RegExp(r'/$'), '');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (config.apiKey != null) 'X-EngageAI-Key': config.apiKey!,
      };

  /// Send recorded audio to the backend for full voice chat processing.
  Future<VoiceChatResult> processVoiceChat({
    required Uint8List audioBytes,
    required String sessionId,
    String audioFormat = 'wav',
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final audioBase64 = base64Encode(audioBytes);

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/v1/voice/chat'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'app_id': config.appId,
          'audio_base64': audioBase64,
          'audio_format': audioFormat,
          'voice': voice,
          if (userContext != null) 'user_context': userContext,
        }),
      ).timeout(Duration(seconds: config.timeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        final responseAudioB64 = data['audio_base64'] as String? ?? '';
        Uint8List? responseAudio;
        if (responseAudioB64.isNotEmpty) {
          responseAudio = base64Decode(responseAudioB64);
        }

        final result = VoiceChatResult(
          sessionId: data['session_id'] as String,
          transcription: data['transcription'] as String? ?? '',
          responseText: data['response_text'] as String? ?? '',
          audioBytes: responseAudio,
          actionType: data['action_type'] as String? ?? 'respond',
          functionCalls: List<Map<String, dynamic>>.from(
            data['function_calls'] ?? [],
          ),
          requiresConfirmation: data['requires_confirmation'] as bool? ?? false,
        );

        onTranscription?.call(result.transcription);
        if (result.audioBytes != null) {
          onAudioResponse?.call(result.audioBytes!);
        }

        return result;
      } else {
        throw Exception('Voice chat failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Transcribe audio only (no chat processing).
  Future<String> transcribeAudio(Uint8List audioBytes, {String filename = 'audio.wav'}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/voice/transcribe'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: filename,
      ));
      request.fields['language'] = config.language;
      _headers.forEach((k, v) => request.headers[k] = v);

      final streamedResponse = await _httpClient.send(request)
          .timeout(Duration(seconds: config.timeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['text'] as String? ?? '';
      } else {
        throw Exception('Transcription failed: ${response.body}');
      }
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Convert text to speech audio.
  Future<Uint8List> synthesizeSpeech(String text, {String? voiceOverride}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/v1/voice/synthesize'),
        headers: _headers,
        body: jsonEncode({
          'text': text,
          'voice': voiceOverride ?? voice,
          'speed': 1.0,
        }),
      ).timeout(Duration(seconds: config.timeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        throw Exception('TTS failed: ${response.body}');
      }
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Get available voices.
  Future<List<String>> getAvailableVoices() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/v1/voice/voices'),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['voices'] ?? []);
      }
    } catch (_) {}
    return ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Result from a voice chat interaction.
class VoiceChatResult {
  final String sessionId;
  final String transcription;
  final String responseText;
  final Uint8List? audioBytes;
  final String actionType;
  final List<Map<String, dynamic>> functionCalls;
  final bool requiresConfirmation;

  const VoiceChatResult({
    required this.sessionId,
    required this.transcription,
    required this.responseText,
    this.audioBytes,
    required this.actionType,
    this.functionCalls = const [],
    this.requiresConfirmation = false,
  });
}