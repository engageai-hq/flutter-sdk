import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rive/rive.dart';
import '../models/character_model.dart';

class EngageCharacterWidget extends StatefulWidget {
  final CharacterState state;
  final CharacterEmotion emotion;
  final CharacterConfig config;
  final bool isSpeaking;
  final List<Viseme> visemes;

  /// URL of the character Rive file, served by the EngageAI backend.
  /// Returned from initialize() — always set for every developer.
  /// Enterprise customers get their custom character URL; others get the default.
  /// Set internally by the SDK — not a developer-facing parameter.
  final String? characterUrl;

  /// API key used to authenticate the character file download.
  /// Passed through internally — never set by developer code.
  final String? apiKey;

  const EngageCharacterWidget({
    super.key,
    this.state = CharacterState.idle,
    this.emotion = CharacterEmotion.neutral,
    this.config = const CharacterConfig(),
    this.isSpeaking = false,
    this.visemes = const [],
    this.characterUrl,
    this.apiKey,
  });

  @override
  State<EngageCharacterWidget> createState() => _EngageCharacterWidgetState();
}

class _EngageCharacterWidgetState extends State<EngageCharacterWidget> {
  RiveWidgetController? _riveController;
  StateMachine? _stateMachine;

  bool _loading = true;
  String? _loadError;

  // In-memory cache keyed by URL — shared across all widget instances.
  // Prevents re-downloading the character file on every widget rebuild.
  static final Map<String, List<int>> _cache = {};

  // Package-aware asset path: when the SDK is consumed as a Flutter package
  // (via git URL or pub.dev), this path resolves to the SDK's own bundled
  // asset, not the consumer app's asset bundle. The pubspec's `flutter:
  // assets:` declaration ships the .riv file with every install.
  static const _assetPath = 'packages/engageai_sdk/assets/character/character.riv';

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      File? file;

      // Try URL-based character first (for enterprise/branded customers).
      // If URL fetch fails for any reason — network error, server down, bad
      // response — gracefully fall back to the bundled default asset rather
      // than crashing the whole widget.
      if (widget.characterUrl != null) {
        try {
          final url = widget.characterUrl!;

          // Use cached bytes if available
          List<int>? bytes = _cache[url];

          if (bytes == null) {
            final headers = <String, String>{};
            if (widget.apiKey != null) headers['X-EngageAI-Key'] = widget.apiKey!;

            final response = await http.get(Uri.parse(url), headers: headers);
            if (response.statusCode != 200) {
              throw Exception('Character fetch failed (${response.statusCode})');
            }

            bytes = response.bodyBytes;
            _cache[url] = bytes; // cache for this session
          }

          file = await File.decode(
            Uint8List.fromList(bytes),
            riveFactory: Factory.rive,
          );
        } catch (e) {
          // URL load failed — log and fall through to bundled-asset path
          debugPrint('[EngageAI] Character URL load failed, using bundled default: $e');
          file = null;
        }
      }

      // If no URL was provided, OR URL load failed, use the bundled asset.
      // The asset is shipped with the SDK package and is always available.
      if (file == null) {
        file = await File.asset(_assetPath, riveFactory: Factory.rive);
      }

      if (file == null) throw Exception('Rive file is null');

      final controller = RiveWidgetController(file);
      _stateMachine = controller.stateMachine;

      debugPrint('[EngageAI] State machine: "${_stateMachine?.name}"');
      // ignore: deprecated_member_use
      for (final i in _stateMachine?.inputs ?? []) {
        debugPrint('[EngageAI]   input: "${i.name}"');
      }

      if (mounted) {
        setState(() {
          _riveController = controller;
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 80));
          if (mounted) _applyState(widget.state);
        });
      }
    } catch (e, stack) {
      debugPrint('[EngageAI] Rive load error: $e\n$stack');
      if (mounted) setState(() { _loading = false; _loadError = e.toString(); });
    }
  }

  void _setInput(String name, bool value) {
    // ignore: deprecated_member_use
    _stateMachine?.boolean(name)?.value = value;
  }

  void _applyState(CharacterState state) {
    // Always clear both first — idle animation plays when both are false
    _setInput('isTalking', false);
    _setInput('isListening', false);

    switch (state) {
      case CharacterState.listening:
        // User is speaking — activate listening
        _setInput('isListening', true);
      case CharacterState.talking:
        // Model is speaking — activate talking
        _setInput('isTalking', true);
      case CharacterState.thinking:
      case CharacterState.waitingConfirmation:
      case CharacterState.idle:
      case CharacterState.celebrating:
      case CharacterState.error:
        // Both false → idle animation runs
        break;
    }

    _riveController?.scheduleRepaint();
    debugPrint('[EngageAI] State: $state');
  }

  @override
  void didUpdateWidget(EngageCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _applyState(widget.state);
  }

  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.config.size;

    if (_loading) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    if (_loadError != null || _riveController == null) {
      return SizedBox(width: size, height: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: RiveWidget(
        controller: _riveController!,
        fit: Fit.contain,
      ),
    );
  }
}
