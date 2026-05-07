import 'dart:ui';
import 'package:flutter/material.dart';
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
  bool _textVisible = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Slight delay so the overlay fade-in finishes first
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _textVisible = true);
      _playWelcome();
    });
  }

  Future<void> _playWelcome() async {
    if (widget.voiceService == null) return;
    try {
      setState(() => _isSpeaking = true);
      final bytes =
          await widget.voiceService!.synthesizeSpeech(widget.welcomeMessage);
      if (mounted && bytes.isNotEmpty) {
        await _audio.playAudioBytes(bytes);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _dismiss() {
    _audio.stopPlayback();
    Navigator.of(context).pop();
  }

  void _openChat() {
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
    return GestureDetector(
      onTap: _dismiss,
      onLongPress: _openChat,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Frosted glass + dark overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
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

            // Character + text
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
                          state: _isSpeaking
                              ? CharacterState.talking
                              : CharacterState.idle,
                          emotion: CharacterEmotion.happy,
                          config: const CharacterConfig(
                              size: 160 * 2.8, showShadow: false),
                          isSpeaking: _isSpeaking,
                          characterUrl: widget.characterUrl,
                          apiKey: widget.apiKey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Welcome message
                  AnimatedOpacity(
                    opacity: _textVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        widget.welcomeMessage,
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

                  const SizedBox(height: 20),

                  AnimatedOpacity(
                    opacity: _textVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Hold to open chat',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap anywhere to dismiss',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
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
