import 'package:flutter/material.dart';
import '../models/character_model.dart';
import 'engage_character_widget.dart';

class EngageCharacterFab extends StatefulWidget {
  final VoidCallback onTap;
  final Color primaryColor;
  final double size;

  const EngageCharacterFab({
    super.key,
    required this.onTap,
    this.primaryColor = const Color(0xFF4F6AFF),
    this.size = 90,
  });

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

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return GestureDetector(
      onTap: widget.onTap,
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
                maxWidth: s * 1.2,
                maxHeight: s * 1.2,
                child: Align(
                  alignment: const Alignment(0, 0.3),
                  child: EngageCharacterWidget(
                    state: CharacterState.idle,
                    emotion: CharacterEmotion.happy,
                    config: CharacterConfig(size: s * 1.2, showShadow: false),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
