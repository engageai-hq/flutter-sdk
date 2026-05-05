import 'package:flutter/material.dart';
import '../core/engageai.dart';
import '../services/voice_service.dart';
import '../models/character_model.dart';
import 'engage_character_widget.dart';
import 'engage_voice_chat_widget.dart';

/// A floating-action-button-style widget that hosts the EngageAI character.
///
/// **Two ways to use it:**
///
/// **1. Default behavior (recommended for most apps):** pass an [engageAI]
///    instance and the FAB will automatically open [EngageAIVoiceChatWidget]
///    when tapped. No [onTap] needed.
///
/// ```dart
/// EngageCharacterFab(
///   engageAI: yourEngageAI,
///   characterUrl: 'https://...',
///   apiKey: 'eai_...',
/// )
/// ```
///
/// **2. Custom behavior:** pass your own [onTap] callback to fully control
///    what happens on tap (e.g., open a different screen, gate behind auth,
///    log analytics first). When [onTap] is provided, the default behavior
///    is skipped.
///
/// ```dart
/// EngageCharacterFab(
///   onTap: () => Navigator.push(context, MyCustomChatRoute()),
///   characterUrl: 'https://...',
///   apiKey: 'eai_...',
/// )
/// ```
///
/// **You must provide either [onTap] OR [engageAI].** If both are null the
/// FAB will throw an assertion error explaining what to do.
class EngageCharacterFab extends StatefulWidget {
  /// Custom tap handler. If provided, this callback runs and the default
  /// voice-chat-opening behavior is skipped.
  ///
  /// Use this when you want full control over what happens on tap. Otherwise
  /// pass [engageAI] and let the FAB handle it.
  final VoidCallback? onTap;

  /// The EngageAI instance to use for the default voice-chat behavior.
  ///
  /// Required if [onTap] is null. When the FAB is tapped, it will push a
  /// new route containing [EngageAIVoiceChatWidget] configured with this
  /// instance.
  final EngageAI? engageAI;

  /// Optional voice service for the default voice-chat widget. If null,
  /// [EngageAIVoiceChatWidget] handles voice initialisation internally.
  final EngageVoiceService? voiceService;

  /// Optional streaming service for the default voice-chat widget.
  final dynamic streamingService;

  /// Title shown in the default voice-chat widget. Defaults to "EngageAI".
  final String voiceChatTitle;

  /// Welcome message shown when the default voice-chat widget opens.
  final String voiceChatWelcomeMessage;

  /// Whether streaming responses should be enabled in the default voice-chat
  /// widget. Defaults to false.
  final bool enableStreaming;

  /// Primary color used for the FAB's pulsing glow.
  final Color primaryColor;

  /// Diameter of the FAB in logical pixels.
  final double size;

  /// Optional URL of a custom character `.riv` file. If null, the SDK's
  /// bundled default character is used.
  final String? characterUrl;

  /// Optional API key, forwarded to character asset requests so enterprise
  /// customers' character URLs can be authenticated server-side.
  final String? apiKey;

  const EngageCharacterFab({
    super.key,
    this.onTap,
    this.engageAI,
    this.voiceService,
    this.streamingService,
    this.voiceChatTitle = 'EngageAI',
    this.voiceChatWelcomeMessage = 'Hi! How can I help you today?',
    this.enableStreaming = false,
    this.primaryColor = const Color(0xFF1D4ED7),
    this.size = 90,
    this.characterUrl,
    this.apiKey,
  }) : assert(
          onTap != null || engageAI != null,
          'EngageCharacterFab needs either an onTap callback OR an engageAI '
          'instance. Without one of these, tapping the FAB does nothing. '
          'For most apps, just pass engageAI and the FAB will automatically '
          'open the voice chat widget on tap.',
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

  /// Default tap behaviour: push a new route containing the voice chat widget.
  /// Only used when [widget.onTap] is null and [widget.engageAI] is provided.
  void _defaultOpenVoiceChat() {
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

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    // If a custom onTap was provided, use it. Otherwise fall back to the
    // default voice-chat-opening behavior.
    final tapHandler = widget.onTap ?? _defaultOpenVoiceChat;

    return GestureDetector(
      onTap: tapHandler,
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
