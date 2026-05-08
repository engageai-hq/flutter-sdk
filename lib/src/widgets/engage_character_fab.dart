import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../core/engageai.dart';
import '../services/voice_service.dart';
import '../services/audio_service.dart';
import '../models/character_model.dart';
import 'engage_character_widget.dart';
import 'engage_voice_chat_widget.dart';

/// A floating-action-button-style widget that hosts the EngageAI character.
///
/// **Tap** → dreamy fullscreen overlay with welcome voice message.
/// **Long press** → opens the full voice/text chat interface.
///
/// **Two ways to use it:**
///
/// **1. Default behavior (recommended):** pass an [engageAI] instance.
///
/// ```dart
/// EngageCharacterFab(
///   engageAI: yourEngageAI,
///   voiceChatTitle: 'ShopFlow AI',
/// )
/// ```
///
/// **2. Custom behavior:** pass your own [onTap] / [onLongPress] callbacks.
///
/// **You must provide either [onTap] OR [engageAI].**
class EngageCharacterFab extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EngageAI? engageAI;
  final EngageVoiceService? voiceService;
  final dynamic streamingService;
  final String voiceChatTitle;
  final String voiceChatWelcomeMessage;
  final bool enableStreaming;
  final Color primaryColor;
  final double size;
  final String? characterUrl;
  final String? apiKey;

  const EngageCharacterFab({
    super.key,
    this.onTap,
    this.onLongPress,
    this.engageAI,
    this.voiceService,
    this.streamingService,
    this.voiceChatTitle = 'EngageAI',
    this.voiceChatWelcomeMessage = 'Hi! How can I help you today?',
    this.enableStreaming = false,
    this.primaryColor = const Color(0xFF1D4ED8),
    this.size = 90,
    this.characterUrl,
    this.apiKey,
  }) : assert(
          onTap != null || engageAI != null,
          'EngageCharacterFab needs either an onTap callback OR an engageAI '
          'instance. Without one of these, tapping the FAB does nothing.',
        );

  @override
  State<EngageCharacterFab> createState() => _FabState();
}

class _FabState extends State<EngageCharacterFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openChat() {
    final engageAI = widget.engageAI;
    if (engageAI == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: EngageAIVoiceChatWidget(
            engageAI: engageAI,
            voiceService: widget.voiceService,
            streamingService: widget.streamingService,
            title: widget.voiceChatTitle,
            primaryColor: widget.primaryColor,
            welcomeMessage: widget.voiceChatWelcomeMessage,
            enableStreaming: widget.enableStreaming,
          ),
        ),
      ),
    );
  }

  void _showDreamyOverlay() {
    final engageAI = widget.engageAI;
    if (engageAI == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => _DreamyOverlayPage(
          engageAI: engageAI,
          voiceService: widget.voiceService,
          welcomeMessage: widget.voiceChatWelcomeMessage,
          primaryColor: widget.primaryColor,
          characterUrl: widget.characterUrl,
          apiKey: widget.apiKey,
          onOpenChat: _openChat,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final tapHandler = widget.onTap ?? _showDreamyOverlay;
    final longPressHandler = widget.onLongPress ??
        (widget.engageAI != null ? _openChat : null);

    return GestureDetector(
      onTap: tapHandler,
      onLongPress: longPressHandler,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(
                    alpha: 0.18 + _pulse.value * 0.12,
                  ),
                  blurRadius: 12 + _pulse.value * 6,
                  spreadRadius: 1 + _pulse.value * 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: OverflowBox(
                alignment: const Alignment(-.1, -0.8),
                maxWidth: s * 2.8,
                maxHeight: s * 2.8,
                child: EngageCharacterWidget(
                  state: CharacterState.idle,
                  emotion: CharacterEmotion.happy,
                  config: CharacterConfig(size: s * 2.8, showShadow: false),
                  characterUrl: widget.characterUrl,
                  apiKey: widget.apiKey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Dreamy overlay ───────────────────────────────────────────────────────────

class _DreamyOverlayPage extends StatefulWidget {
  final EngageAI engageAI;
  final EngageVoiceService? voiceService;
  final String welcomeMessage;
  final Color primaryColor;
  final String? characterUrl;
  final String? apiKey;
  final VoidCallback onOpenChat;

  const _DreamyOverlayPage({
    required this.engageAI,
    required this.voiceService,
    required this.welcomeMessage,
    required this.primaryColor,
    required this.characterUrl,
    required this.apiKey,
    required this.onOpenChat,
  });

  @override
  State<_DreamyOverlayPage> createState() => _DreamyOverlayPageState();
}

class _DreamyOverlayPageState extends State<_DreamyOverlayPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  final EngageAudioService _audio = EngageAudioService();

  bool _isSpeaking = false;
  bool _isRecording = false;
  bool _isLoadingResponse = false;
  bool _micPointerDown = false;
  bool _textVisible = false;
  CharacterState _characterState = CharacterState.idle;
  String? _responseText;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _textVisible = true);
      _playWelcome();
    });
  }

  Future<void> _playWelcome() async {
    if (widget.voiceService == null) return;
    try {
      setState(() { _isSpeaking = true; _characterState = CharacterState.talking; });
      final bytes = await widget.voiceService!.synthesizeSpeech(widget.welcomeMessage);
      if (mounted && bytes.isNotEmpty) await _audio.playAudioBytes(bytes);
    } catch (_) {
    } finally {
      if (mounted) setState(() { _isSpeaking = false; _characterState = CharacterState.idle; });
    }
  }

  Future<void> _startRecording() async {
    if (widget.voiceService == null) return;
    await _audio.stopPlayback();
    if (mounted) setState(() { _isSpeaking = false; });

    final ok = await _audio.hasPermission();
    if (!ok || !mounted) return;

    final started = await _audio.startRecording();
    if (started && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isRecording = true;
        _characterState = CharacterState.listening;
      });
      // Race: user released before startRecording() finished
      if (!_micPointerDown) _stopAndProcess();
    }
  }

  Future<void> _stopAndProcess() async {
    if (!_isRecording) return;
    setState(() { _isRecording = false; _characterState = CharacterState.thinking; });

    try {
      final audioBytes = await _audio.stopRecording();
      if (audioBytes == null || audioBytes.isEmpty) {
        if (mounted) setState(() => _characterState = CharacterState.idle);
        return;
      }

      if (widget.voiceService == null) return;

      if (mounted) setState(() => _isLoadingResponse = true);
      final transcription = await widget.voiceService!.transcribeAudio(audioBytes);

      if (transcription.isEmpty) {
        if (mounted) setState(() { _isLoadingResponse = false; _characterState = CharacterState.idle; });
        return;
      }

      final action = await widget.engageAI.sendMessage(transcription);

      if (mounted) setState(() {
        _isLoadingResponse = false;
        if (action.message != null && action.message!.isNotEmpty) {
          _responseText = action.message;
        }
      });

      if (action.message != null && action.message!.isNotEmpty) {
        final bytes = await widget.voiceService!.synthesizeSpeech(action.message!);
        if (mounted && bytes.isNotEmpty) {
          setState(() { _isSpeaking = true; _characterState = CharacterState.talking; });
          await _audio.playAudioBytes(bytes);
        }
      }

      if (mounted) setState(() { _isSpeaking = false; _characterState = CharacterState.idle; });
    } catch (_) {
      if (mounted) setState(() { _isLoadingResponse = false; _characterState = CharacterState.idle; });
    }
  }

  void _dismiss() {
    if (_isRecording) _audio.stopRecording();
    _audio.stopPlayback();
    Navigator.of(context).pop();
  }

  void _openChat() {
    if (_isRecording) _audio.stopRecording();
    _audio.stopPlayback();
    Navigator.of(context).pop();
    widget.onOpenChat();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _responseText ?? widget.welcomeMessage;

    return GestureDetector(
      onTap: _dismiss,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Frosted glass + dark overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ),

            // Expanding ripple rings
            Center(
              child: AnimatedBuilder(
                animation: _ringCtrl,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (i) {
                    final offset = i / 3.0;
                    final progress = (_ringCtrl.value + offset) % 1.0;
                    return Opacity(
                      opacity: (1.0 - progress).clamp(0.0, 1.0),
                      child: Container(
                        width: 160 + progress * 160,
                        height: 160 + progress * 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.primaryColor
                                .withValues(alpha: 0.5 - progress * 0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Character + text + controls
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Character orb
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: OverflowBox(
                        alignment: const Alignment(-0.1, -0.8),
                        maxWidth: 160 * 2.8,
                        maxHeight: 160 * 2.8,
                        child: EngageCharacterWidget(
                          state: _characterState,
                          emotion: CharacterEmotion.happy,
                          config: const CharacterConfig(size: 160 * 2.8, showShadow: false),
                          isSpeaking: _isSpeaking,
                          characterUrl: widget.characterUrl,
                          apiKey: widget.apiKey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Message text (welcome or AI response)
                  AnimatedOpacity(
                    opacity: _textVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        displayText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Controls
                  AnimatedOpacity(
                    opacity: _textVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        if (widget.voiceService != null) ...[
                          // Press-and-hold mic button
                          // GestureDetector absorbs the tap so the outer
                          // onTap:_dismiss doesn't fire on pointer release
                          GestureDetector(
                            onTap: () {},
                            child: Listener(
                            onPointerDown: (_isLoadingResponse || _isRecording)
                                ? null
                                : (_) {
                                    _micPointerDown = true;
                                    _startRecording();
                                  },
                            onPointerUp: (_) {
                              _micPointerDown = false;
                              _stopAndProcess();
                            },
                            onPointerCancel: (_) {
                              _micPointerDown = false;
                              _stopAndProcess();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? Colors.red : widget.primaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : widget.primaryColor)
                                        .withValues(alpha: 0.55),
                                    blurRadius: _isRecording ? 28 : 20,
                                    spreadRadius: _isRecording ? 5 : 2,
                                  ),
                                ],
                              ),
                              child: _isLoadingResponse
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Icon(
                                      _isRecording ? Icons.stop_rounded : Icons.mic,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            ),
                          ), // Listener
                          ), // GestureDetector
                          const SizedBox(height: 10),
                          Text(
                            _isRecording
                                ? 'Release to send'
                                : _isLoadingResponse
                                    ? 'Processing...'
                                    : 'Hold to speak',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          // No voice service — fall back to open chat
                          GestureDetector(
                            onTap: _openChat,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              decoration: BoxDecoration(
                                color: widget.primaryColor,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.primaryColor.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ask me anything',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Secondary: open full chat
                        GestureDetector(
                          onTap: _openChat,
                          child: Text(
                            'Open full chat →',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Tap anywhere to dismiss',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
