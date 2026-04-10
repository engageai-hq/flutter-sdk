import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../models/character_model.dart';

class EngageCharacterWidget extends StatefulWidget {
  final CharacterState state;
  final CharacterEmotion emotion;
  final CharacterConfig config;
  final bool isSpeaking;
  final List<Viseme> visemes;

  const EngageCharacterWidget({
    super.key,
    this.state = CharacterState.idle,
    this.emotion = CharacterEmotion.neutral,
    this.config = const CharacterConfig(),
    this.isSpeaking = false,
    this.visemes = const [],
  });

  @override
  State<EngageCharacterWidget> createState() => _EngageCharacterWidgetState();
}

class _EngageCharacterWidgetState extends State<EngageCharacterWidget> {
  RiveWidgetController? _riveController;
  StateMachine? _stateMachine;

  bool _loading = true;
  String? _loadError;

  static const _assetPath = 'assets/character/character.riv';

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      final file = await File.asset(_assetPath, riveFactory: Factory.rive);
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _applyState(widget.state));
      }
    } catch (e, stack) {
      debugPrint('[EngageAI] Rive load error: $e\n$stack');
      if (mounted) setState(() { _loading = false; _loadError = e.toString(); });
    }
  }

  void _setInput(String name, bool value) {
    // ignore: deprecated_member_use
    _stateMachine?.boolean(name)?.value = value;
    _riveController?.scheduleRepaint();
  }

  void _applyState(CharacterState state) {
    switch (state) {
      case CharacterState.listening:
      case CharacterState.thinking:
      case CharacterState.waitingConfirmation:
        _setInput('isTalking', false);
        _setInput('isListening', true);

      case CharacterState.talking:
        _setInput('isListening', false);
        _setInput('isTalking', true);

      case CharacterState.idle:
      case CharacterState.celebrating:
      case CharacterState.error:
        _setInput('isTalking', false);
        _setInput('isListening', false);
    }

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
