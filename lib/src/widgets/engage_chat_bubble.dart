import 'package:flutter/material.dart';
import '../core/engageai.dart';
import 'engage_chat_widget.dart';

/// A floating action button that opens the EngageAI chat overlay.
///
/// Add this to your app's Scaffold to give users quick access to the AI assistant.
///
/// ```dart
/// Scaffold(
///   body: YourAppContent(),
///   floatingActionButton: EngageAIChatBubble(
///     engageAI: myEngageAIInstance,
///   ),
/// )
/// ```
class EngageAIChatBubble extends StatefulWidget {
  final EngageAI engageAI;
  final String title;
  final Color primaryColor;
  final String welcomeMessage;
  final double size;
  final Alignment alignment;

  const EngageAIChatBubble({
    super.key,
    required this.engageAI,
    this.title = 'Assistant',
    this.primaryColor = const Color(0xFF6C63FF),
    this.welcomeMessage = 'Hi! 👋 How can I help you today?',
    this.size = 60,
    this.alignment = Alignment.bottomRight,
  });

  @override
  State<EngageAIChatBubble> createState() => _EngageAIChatBubbleState();
}

class _EngageAIChatBubbleState extends State<EngageAIChatBubble>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat overlay
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.black54),
            ),
          ),
        if (_isOpen)
          Positioned(
            right: 16,
            bottom: 80,
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.65,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: EngageAIChatWidget(
                  engageAI: widget.engageAI,
                  title: widget.title,
                  primaryColor: widget.primaryColor,
                  welcomeMessage: widget.welcomeMessage,
                ),
              ),
            ),
          ),

        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: widget.primaryColor,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isOpen
                  ? const Icon(Icons.close, key: ValueKey('close'), color: Colors.white)
                  : const Icon(Icons.chat, key: ValueKey('chat'), color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
