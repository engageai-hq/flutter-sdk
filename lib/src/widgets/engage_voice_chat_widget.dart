import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/engageai.dart';
import '../models/agent_action.dart';
import '../models/chat_message.dart';
import '../models/character_model.dart';
import '../services/voice_service.dart';
import '../services/audio_service.dart';
import 'engage_character_widget.dart';

class EngageAIVoiceChatWidget extends StatefulWidget {
  final EngageAI engageAI;
  final EngageVoiceService? voiceService;
  final dynamic streamingService;
  final String title;
  final Color primaryColor;
  final String welcomeMessage;
  final CharacterConfig characterConfig;
  final bool showCharacter;
  final bool enableStreaming;

  const EngageAIVoiceChatWidget({
    super.key,
    required this.engageAI,
    this.voiceService,
    this.streamingService,
    this.title = 'EngageAI',
    this.primaryColor = const Color(0xFF6C63FF),
    this.welcomeMessage = 'Hi! How can I help you today?',
    this.characterConfig = const CharacterConfig(),
    this.showCharacter = true,
    this.enableStreaming = false,
  });

  @override
  State<EngageAIVoiceChatWidget> createState() => _State();
}

class _State extends State<EngageAIVoiceChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EngageAudioService _audioService = EngageAudioService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isSpeaking = false;
  bool _awaitingConfirmation = false;
  bool _isFetchingAudio = false;
  CharacterState _characterState = CharacterState.idle;
  CharacterEmotion _characterEmotion = CharacterEmotion.happy;

  @override
  void initState() {
    super.initState();

    widget.engageAI.onMessagesChanged = (msgs) {
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    };

    _audioService.onPlaybackComplete = () {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          if (_characterState == CharacterState.talking) {
            _characterState = CharacterState.idle;
            _characterEmotion = CharacterEmotion.happy;
          }
        });
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = widget.engageAI.messages;
      if (existing.isNotEmpty) {
        // Restore history when reopening the chat
        setState(() => _messages = existing);
        _scrollToBottom();
      } else {
        setState(() {
          _messages = [
            ChatMessage(
              id: 'welcome',
              content: widget.welcomeMessage,
              sender: MessageSender.agent,
              timestamp: DateTime.now(),
            ),
          ];
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _interrupt() async {
    await _audioService.stopHumming();
    if (_isSpeaking) {
      await _audioService.stopPlayback();
      setState(() {
        _isSpeaking = false;
        _characterState = CharacterState.idle;
        _characterEmotion = CharacterEmotion.happy;
      });
    }
  }

  Future<void> _processMessage(String text) async {
    await _interrupt();

    setState(() {
      _isLoading = true;
      _awaitingConfirmation = false;
      _characterState = CharacterState.thinking;
      _characterEmotion = CharacterEmotion.thinking;
    });

    _audioService.startHumming();

    try {
      final action = await widget.engageAI.sendMessage(text);

      await _audioService.stopHumming();

      // Fire TTS IMMEDIATELY — don't wait for setState
      Future<void>? ttsFuture;
      if (widget.voiceService != null &&
          action.message != null &&
          action.message!.isNotEmpty &&
          action.actionType != AgentActionType.functionCall) {
        ttsFuture = _fetchAndPlayAudio(action.message!);
      }

      // Show text
      setState(() {
        _isLoading = false;
        _messages = widget.engageAI.messages;
      });
      _scrollToBottom();

      if (action.actionType == AgentActionType.confirm) {
        setState(() {
          _awaitingConfirmation = true;
          _characterState = CharacterState.waitingConfirmation;
          _characterEmotion = CharacterEmotion.expectant;
        });
      }

      // Wait for TTS if it was started
      if (ttsFuture != null) {
        await ttsFuture;
      } else if (action.actionType != AgentActionType.confirm) {
        _fadeToIdle(seconds: 2);
      }

    } catch (e) {
      await _audioService.stopHumming();
      setState(() {
        _isLoading = false;
        _messages = widget.engageAI.messages;
        _characterState = CharacterState.error;
        _characterEmotion = CharacterEmotion.worried;
      });
      _scrollToBottom();
      _fadeToIdle();
    }
  }

  Future<void> _fetchAndPlayAudio(String text) async {
    try {
      setState(() => _isFetchingAudio = true);
      final audioBytes = await widget.voiceService!.synthesizeSpeech(text);
      setState(() => _isFetchingAudio = false);

      if (!mounted || _isLoading || _isRecording) return;

      if (audioBytes.isNotEmpty) {
        setState(() {
          _isSpeaking = true;
          _characterState = CharacterState.talking;
          _characterEmotion = CharacterEmotion.happy;
        });
        await _audioService.playAudioBytes(audioBytes);
      }
    } catch (e) {
      setState(() => _isFetchingAudio = false);
      debugPrint('TTS error: $e');
      _fadeToIdle();
    }
  }
  void _speakInBackground(String? text) async {
    if (text == null || text.isEmpty) {
      _fadeToIdle(seconds: 2);
      return;
    }
    await _fetchAndPlayAudio(text);
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;
    _textController.clear();
    await _processMessage(text);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndProcess();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    await _interrupt();

    final ok = await _audioService.hasPermission();
    if (!ok) {
      _showSnack('Microphone permission required');
      return;
    }
    final started = await _audioService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _characterState = CharacterState.listening;
        _characterEmotion = CharacterEmotion.happy;
      });
    }
  }

  Future<void> _stopAndProcess() async {
    setState(() {
      _isRecording = false;
      _characterState = CharacterState.thinking;
      _characterEmotion = CharacterEmotion.thinking;
    });

    try {
      final audioBytes = await _audioService.stopRecording();
      if (audioBytes == null || audioBytes.isEmpty) {
        setState(() {
          _characterState = CharacterState.idle;
          _characterEmotion = CharacterEmotion.happy;
        });
        return;
      }

      if (widget.voiceService == null) {
        setState(() { _characterState = CharacterState.idle; });
        return;
      }

      // Start humming while transcribing
      _audioService.startHumming();
      setState(() => _isLoading = true);

      final transcription = await widget.voiceService!.transcribeAudio(audioBytes);

      if (transcription.isEmpty) {
        await _audioService.stopHumming();
        setState(() {
          _isLoading = false;
          _characterState = CharacterState.idle;
          _characterEmotion = CharacterEmotion.happy;
        });
        _showSnack("Didn't catch that. Try again?");
        return;
      }

      // Stop humming before processMessage starts its own
      await _audioService.stopHumming();
      setState(() => _isLoading = false);

      await _processMessage(transcription);

    } catch (e) {
      await _audioService.stopHumming();
      setState(() {
        _isLoading = false;
        _characterState = CharacterState.error;
        _characterEmotion = CharacterEmotion.worried;
      });
      _showSnack('Voice error: $e');
      _fadeToIdle();
    }
  }

  Future<void> _handleConfirmation(bool confirmed) async {
    await _interrupt();

    setState(() {
      _isLoading = true;
      _awaitingConfirmation = false;
      _characterState = CharacterState.thinking;
      _characterEmotion = CharacterEmotion.thinking;
    });

    _audioService.startHumming();

    try {
      final action = confirmed
          ? await widget.engageAI.confirm()
          : await widget.engageAI.deny();

      await _audioService.stopHumming();

      setState(() {
        _isLoading = false;
        _messages = widget.engageAI.messages;
      });
      _scrollToBottom();
      _speakInBackground(action.message);

    } catch (e) {
      await _audioService.stopHumming();
      setState(() { _isLoading = false; });
      _showSnack('Error: $e');
      _fadeToIdle();
    }
  }

  void _fadeToIdle({int seconds = 3}) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted && !_isSpeaking && !_isRecording &&
          _characterState != CharacterState.waitingConfirmation) {
        setState(() {
          _characterState = CharacterState.idle;
          _characterEmotion = CharacterEmotion.happy;
        });
      }
    });
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMessages()),
        if (_awaitingConfirmation) _buildConfirmBar(),
        if (_isRecording) _buildRecordingBar(),
        _buildInput(),
      ],
    );
  }

  Widget _buildHeader() {
    final (String label, Color dot) = switch (true) {
      _ when _isRecording => ('Listening...', Colors.red),
      _ when _isLoading => ('Thinking...', Colors.orange),
      _ when _isFetchingAudio => ('Preparing voice...', Colors.blue),
      _ when _isSpeaking => ('Tap to stop', Colors.greenAccent),
      _ => ('Online', Colors.greenAccent),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { _interrupt(); Navigator.of(context).maybePop(); },
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.title, style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isSpeaking ? _interrupt : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 8, height: 8,
                            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(label, style: TextStyle(
                            color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showCharacter)
              GestureDetector(
                onTap: _isSpeaking ? _interrupt : null,
                child: SizedBox(
                  height: widget.characterConfig.size + 10,
                  child: EngageCharacterWidget(
                    state: _characterState,
                    emotion: _characterEmotion,
                    config: widget.characterConfig,
                    isSpeaking: _isSpeaking,
                    characterUrl: widget.engageAI.characterUrl,
                    apiKey: widget.engageAI.config.apiKey,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() => Container(
    color: const Color(0xFFF5F5F5),
    child: ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    ),
  );

  Widget _buildConfirmBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Colors.white,
    child: Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: () => _handleConfirmation(false),
        icon: const Icon(Icons.close, size: 18), label: const Text('Cancel'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12)),
      )),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton.icon(
        onPressed: () => _handleConfirmation(true),
        icon: const Icon(Icons.check, size: 18), label: const Text('Confirm'),
        style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12)),
      )),
    ]),
  );

  Widget _buildRecordingBar() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    color: Colors.red.withOpacity(0.05),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 12, height: 12,
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      const Text('Recording... Tap mic to stop',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildInput() => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    decoration: BoxDecoration(color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 4, offset: const Offset(0, -2))]),
    child: SafeArea(
      top: false,
      child: Row(children: [
        GestureDetector(
          onTap: _isLoading ? null : _toggleRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : widget.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : widget.primaryColor, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Type or tap mic to speak...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none),
            filled: true, fillColor: const Color(0xFFF0F0F0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendTextMessage(),
          enabled: !_isLoading && !_isRecording,
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isLoading || _isRecording ? null : _sendTextMessage,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: widget.primaryColor, shape: BoxShape.circle),
            child: _isLoading
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ]),
    ),
  );

  Widget _bubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) Container(
            width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.smart_toy, color: widget.primaryColor, size: 16),
          ),
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? widget.primaryColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(msg.content,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15)),
          )),
        ],
      ),
    );
  }
}
