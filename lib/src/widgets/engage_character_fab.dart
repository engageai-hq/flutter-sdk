import 'dart:math';
import 'package:flutter/material.dart';

class EngageCharacterFab extends StatefulWidget {
  final VoidCallback onTap;
  final Color primaryColor;
  final double size;

  const EngageCharacterFab({
    super.key,
    required this.onTap,
    this.primaryColor = const Color(0xFF4F6AFF),
    this.size = 62,
  });

  @override
  State<EngageCharacterFab> createState() => _FabState();
}

class _FabState extends State<EngageCharacterFab>
    with TickerProviderStateMixin {
  late AnimationController _blinkCtrl;
  late AnimationController _breathCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _blink;
  late Animation<double> _breath;
  late Animation<double> _pulse;

  static const Color _skin = Color(0xFF6B3A2A);
  static const Color _skinLight = Color(0xFF7D4A38);
  static const Color _hair = Color(0xFF1A1008);
  static const Color _lip = Color(0xFFA83830);

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 150));
    _blink = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));
    _startBlinking();

    _breathCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _breath = Tween<double>(begin: -1.5, end: 1.5).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2500 + Random().nextInt(3000)));
      if (mounted) {
        await _blinkCtrl.forward();
        if (mounted) await _blinkCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _breathCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: Listenable.merge([_blinkCtrl, _breathCtrl, _pulseCtrl]),
      builder: (context, _) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.translate(
            offset: Offset(0, _breath.value),
            child: SizedBox(
              width: s + 4,
              height: s + 20,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Shadow
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: s * 0.4, height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ),
                  ),

                  // Hair behind
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: s * 0.92,
                      height: s * 0.85,
                      decoration: BoxDecoration(
                        color: _hair,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(s * 0.42),
                          topRight: Radius.circular(s * 0.42),
                          bottomLeft: Radius.circular(s * 0.06),
                          bottomRight: Radius.circular(s * 0.06),
                        ),
                      ),
                    ),
                  ),

                  // Face
                  Positioned(
                    bottom: s * 0.08,
                    child: Container(
                      width: s * 0.78,
                      height: s * 0.75,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.2, -0.2),
                          colors: [_skinLight, _skin],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(s * 0.38),
                          topRight: Radius.circular(s * 0.38),
                          bottomLeft: Radius.circular(s * 0.3),
                          bottomRight: Radius.circular(s * 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withOpacity(0.12 + _pulse.value * 0.1),
                            blurRadius: 8 + _pulse.value * 4,
                            spreadRadius: 1 + _pulse.value,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Left eye
                          Positioned(
                            top: s * 0.22,
                            left: s * 0.1,
                            child: _eye(s * 0.14),
                          ),
                          // Right eye
                          Positioned(
                            top: s * 0.22,
                            right: s * 0.1,
                            child: _eye(s * 0.14),
                          ),
                          // Nose
                          Positioned(
                            top: s * 0.38,
                            left: 0, right: 0,
                            child: Center(
                              child: Container(
                                width: s * 0.05, height: s * 0.04,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: _skin.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                          // Smile
                          Positioned(
                            top: s * 0.46,
                            left: 0, right: 0,
                            child: Center(
                              child: CustomPaint(
                                size: Size(s * 0.22, s * 0.1),
                                painter: _LipMiniPainter(color: _lip),
                              ),
                            ),
                          ),
                          // Blush
                          Positioned(
                            top: s * 0.4,
                            left: s * 0.04,
                            child: Container(
                              width: s * 0.1, height: s * 0.04,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFD06050).withOpacity(0.12),
                              ),
                            ),
                          ),
                          Positioned(
                            top: s * 0.4,
                            right: s * 0.04,
                            child: Container(
                              width: s * 0.1, height: s * 0.04,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFD06050).withOpacity(0.12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hair front strands
                  Positioned(
                    bottom: s * 0.15,
                    left: (s + 4 - s * 0.92) / 2,
                    child: Container(
                      width: s * 0.08, height: s * 0.5,
                      decoration: BoxDecoration(
                        color: _hair,
                        borderRadius: BorderRadius.circular(s * 0.03),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: s * 0.15,
                    right: (s + 4 - s * 0.92) / 2,
                    child: Container(
                      width: s * 0.08, height: s * 0.5,
                      decoration: BoxDecoration(
                        color: _hair,
                        borderRadius: BorderRadius.circular(s * 0.03),
                      ),
                    ),
                  ),

                  // Earrings
                  Positioned(
                    bottom: s * 0.18,
                    left: (s + 4 - s * 0.92) / 2 - 2,
                    child: Container(
                      width: s * 0.06, height: s * 0.08,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s * 0.03),
                        border: Border.all(color: const Color(0xFFF0E8D8), width: 1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: s * 0.18,
                    right: (s + 4 - s * 0.92) / 2 - 2,
                    child: Container(
                      width: s * 0.06, height: s * 0.08,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s * 0.03),
                        border: Border.all(color: const Color(0xFFF0E8D8), width: 1.5),
                      ),
                    ),
                  ),

                  // Chef hat
                  Positioned(
                    top: 0,
                    child: SizedBox(
                      width: s * 0.52,
                      height: s * 0.28,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: s * 0.44, height: s * 0.05,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8D0D0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: s * 0.04,
                            child: Container(
                              width: s * 0.48, height: s * 0.24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F0F0),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(s * 0.22),
                                  topRight: Radius.circular(s * 0.22),
                                  bottomLeft: Radius.circular(s * 0.04),
                                  bottomRight: Radius.circular(s * 0.04),
                                ),
                                boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                )],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _eye(double size) {
    final bs = _blink.value;
    return Container(
      width: size,
      height: size * 0.6 * max(bs, 0.1),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EE),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.5),
          topRight: Radius.circular(size * 0.5),
          bottomLeft: Radius.circular(size * 0.4),
          bottomRight: Radius.circular(size * 0.4),
        ),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 0.5),
      ),
      child: bs > 0.3
          ? Center(
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1008),
                  shape: BoxShape.circle,
                ),
                child: Align(
                  alignment: const Alignment(0.3, -0.3),
                  child: Container(
                    width: size * 0.1,
                    height: size * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _LipMiniPainter extends CustomPainter {
  final Color color;
  _LipMiniPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    // Upper lip
    path.moveTo(size.width * 0.1, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.5, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.1, size.width * 0.9, size.height * 0.4);
    // Lower lip
    path.quadraticBezierTo(size.width * 0.5, size.height * 1.1, size.width * 0.1, size.height * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LipMiniPainter old) => color != old.color;
}
