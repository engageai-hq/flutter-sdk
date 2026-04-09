import 'dart:math';
import 'package:flutter/material.dart';
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
  State<EngageCharacterWidget> createState() => _CharState();
}

class _CharState extends State<EngageCharacterWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _mouthCtrl;
  late AnimationController _blinkCtrl;
  late AnimationController _bounceCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _breathY;
  late Animation<double> _breathScale;
  late Animation<double> _blink;
  late Animation<double> _bounce;
  late Animation<double> _pulse;

  // Colors matching the reference
  static const Color _skinBase = Color(0xFF6B3A2A);

  static const Color _skinDark = Color(0xFF5A2E1E);
  static const Color _skinHighlight = Color(0xFF8B5A48);
  static const Color _hairColor = Color(0xFF1A1008);
  static const Color _lipColor = Color(0xFFA83830);
  static const Color _lipDark = Color(0xFF8B2020);
  static const Color _eyeWhite = Color(0xFFFAF5EE);
  static const Color _irisColor = Color(0xFF1A1008);
  static const Color _browColor = Color(0xFF1A1008);
  static const Color _hatWhite = Color(0xFFF5F0F0);
  static const Color _hatShadow = Color(0xFFE0D8D8);
  static const Color _hatBand = Color(0xFFD8D0D0);
  static const Color _earringColor = Color(0xFFF0E8D8);

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _breathY = Tween<double>(begin: -2.5, end: 2.5).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));
    _breathScale = Tween<double>(begin: 1.0, end: 1.008).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

    _mouthCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));

    _blinkCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 150));
    _blink = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));
    _startBlinking();

    _bounceCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _bounce = Tween<double>(begin: 0, end: -18).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 0.8).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 3000 + Random().nextInt(2000)));
      if (mounted && !widget.isSpeaking) {
        await _blinkCtrl.forward();
        if (mounted) await _blinkCtrl.reverse();
      }
    }
  }

  @override
  void didUpdateWidget(EngageCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == CharacterState.celebrating) {
        _bounceCtrl.forward(from: 0);
      }
    }
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _animateMouth();
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _mouthCtrl.stop();
      _mouthCtrl.value = 0;
    }
  }

  void _animateMouth() async {
    while (mounted && widget.isSpeaking) {
      _mouthCtrl.duration = Duration(milliseconds: 70 + Random().nextInt(90));
      await _mouthCtrl.forward();
      await _mouthCtrl.reverse();
      await Future.delayed(Duration(milliseconds: 15 + Random().nextInt(35)));
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _mouthCtrl.dispose();
    _blinkCtrl.dispose();
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathCtrl, _mouthCtrl, _blinkCtrl, _bounceCtrl, _pulseCtrl,
      ]),
      builder: (context, _) {
        return SizedBox(
          width: widget.config.size,
          height: widget.config.size,
          child: Transform.translate(
            offset: Offset(0, _breathY.value + _bounce.value),
            child: Transform.scale(
              scale: _breathScale.value,
              child: _buildCharacter(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacter() {
    final s = widget.config.size;

    double tilt = 0;
    switch (widget.state) {
      case CharacterState.listening: tilt = 0.06;
      case CharacterState.thinking: tilt = -0.07;
      case CharacterState.waitingConfirmation: tilt = 0.04;
      default: tilt = sin(_breathCtrl.value * pi * 2) * 0.01;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow
        if (widget.config.showShadow)
          Positioned(
            bottom: s * 0.02,
            child: Container(
              width: s * 0.3,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.black.withOpacity(0.06),
              ),
            ),
          ),

        // Hair behind head
        Positioned(
          top: s * 0.2,
          child: Transform.rotate(
            angle: tilt,
            child: _buildHairBack(s),
          ),
        ),

        // Head
        Positioned(
          top: s * 0.2,
          child: Transform.rotate(
            angle: tilt,
            child: _buildHead(s),
          ),
        ),

        // Hair front (framing)
        Positioned(
          top: s * 0.2,
          child: Transform.rotate(
            angle: tilt,
            child: _buildHairFront(s),
          ),
        ),

        // Earrings
        Positioned(
          top: s * 0.2,
          child: Transform.rotate(
            angle: tilt,
            child: _buildEarrings(s),
          ),
        ),

        // Chef hat
        Positioned(
          top: s * 0.0,
          child: Transform.rotate(
            angle: tilt * 0.5,
            child: _buildChefHat(s),
          ),
        ),

        // State badge
        Positioned(
          top: s * 0.03,
          right: s * 0.1,
          child: _buildBadge(),
        ),
      ],
    );
  }

  Widget _buildHairBack(double s) {
    final headW = s * 0.48;
    final headH = s * 0.52;
    return SizedBox(
      width: headW + s * 0.06,
      height: headH * 0.7,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Short natural hair — sits just above/at ear level
          Positioned(
            top: headH * 0.12,
            child: Container(
              width: headW + s * 0.04,
              height: headH * 0.48,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headW * 0.48),
                  topRight: Radius.circular(headW * 0.48),
                  bottomLeft: Radius.circular(headW * 0.22),
                  bottomRight: Radius.circular(headW * 0.22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHead(double s) {
    final headW = s * 0.48;
    final headH = s * 0.52;

    return SizedBox(
      width: headW,
      height: headH,
      child: Stack(
        children: [
          // Face shape — slightly oval
          Positioned(
            top: headH * 0.05,
            left: headW * 0.02,
            child: Container(
              width: headW * 0.96,
              height: headH * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headW * 0.48),
                  topRight: Radius.circular(headW * 0.48),
                  bottomLeft: Radius.circular(headW * 0.38),
                  bottomRight: Radius.circular(headW * 0.38),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_skinHighlight, _skinBase, _skinDark],
                  stops: const [0.0, 0.4, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _skinDark.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // Forehead highlight
          Positioned(
            top: headH * 0.15,
            left: headW * 0.3,
            child: Container(
              width: headW * 0.25,
              height: headH * 0.08,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Left eyebrow — arched
          Positioned(
            top: headH * 0.35,
            left: headW * 0.14,
            child: _buildEyebrow(headW * 0.3, false),
          ),
          // Right eyebrow
          Positioned(
            top: headH * 0.35,
            right: headW * 0.14,
            child: _buildEyebrow(headW * 0.3, true),
          ),

          // Left eye — almond shaped
          Positioned(
            top: headH * 0.42,
            left: headW * 0.12,
            child: _buildAlmondEye(headW * 0.25, headH * 0.13, false),
          ),
          // Right eye
          Positioned(
            top: headH * 0.42,
            right: headW * 0.12,
            child: _buildAlmondEye(headW * 0.25, headH * 0.13, true),
          ),

          // Nose
          Positioned(
            top: headH * 0.58,
            left: 0, right: 0,
            child: Center(child: _buildNose(headW)),
          ),

          // Cheek blush
          if (widget.emotion.happiness > 0.5) ...[
            Positioned(
              top: headH * 0.6,
              left: headW * 0.06,
              child: Container(
                width: headW * 0.18,
                height: headH * 0.06,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFD06050).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              top: headH * 0.6,
              right: headW * 0.06,
              child: Container(
                width: headW * 0.18,
                height: headH * 0.06,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFD06050).withOpacity(0.15),
                ),
              ),
            ),
          ],

          // Mouth
          Positioned(
            top: headH * 0.72,
            left: 0, right: 0,
            child: Center(child: _buildMouth(headW * 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildHairFront(double s) {
    final headW = s * 0.48;
    final headH = s * 0.52;

    return SizedBox(
      width: headW + s * 0.08,
      height: headH,
      child: Stack(
        children: [
          // Left hair strand — short, just to ear level
          Positioned(
            top: headH * 0.12,
            left: 0,
            child: Container(
              width: s * 0.055,
              height: headH * 0.38,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(s * 0.03),
                  bottomLeft: Radius.circular(s * 0.03),
                  bottomRight: Radius.circular(s * 0.05),
                ),
              ),
            ),
          ),
          // Right hair strand — short, just to ear level
          Positioned(
            top: headH * 0.12,
            right: 0,
            child: Container(
              width: s * 0.055,
              height: headH * 0.38,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(s * 0.03),
                  bottomRight: Radius.circular(s * 0.03),
                  bottomLeft: Radius.circular(s * 0.05),
                ),
              ),
            ),
          ),
          // Hair top/bangs
          Positioned(
            top: headH * 0.05,
            left: s * 0.02,
            right: s * 0.02,
            child: Container(
              height: headH * 0.2,
              decoration: BoxDecoration(
                color: _hairColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headW * 0.45),
                  topRight: Radius.circular(headW * 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarrings(double s) {
    final headW = s * 0.48;
    final headH = s * 0.52;

    return SizedBox(
      width: headW + s * 0.14,
      height: headH,
      child: Stack(
        children: [
          // Left earring
          Positioned(
            top: headH * 0.5,
            left: s * 0.005,
            child: _buildHoopEarring(s * 0.06),
          ),
          // Right earring
          Positioned(
            top: headH * 0.5,
            right: s * 0.005,
            child: _buildHoopEarring(s * 0.06),
          ),
        ],
      ),
    );
  }

  Widget _buildHoopEarring(double size) {
    return Container(
      width: size,
      height: size * 1.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: _earringColor,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildEyebrow(double width, bool flip) {
    final raised = widget.state == CharacterState.listening ||
        widget.state == CharacterState.waitingConfirmation;

    return Transform.translate(
      offset: Offset(0, raised ? -2 : 0),
      child: CustomPaint(
        size: Size(width, width * 0.25),
        painter: _EyebrowPainter(
          color: _browColor,
          flip: flip,
          worried: widget.emotion.concern > 0.5,
        ),
      ),
    );
  }

  Widget _buildAlmondEye(double width, double height, bool isRight) {
    final bs = _blink.value;
    double lx = 0, ly = 0;
    if (widget.state == CharacterState.thinking) { lx = isRight ? -1 : -1; ly = -1; }
    if (widget.state == CharacterState.listening) { lx = isRight ? 0.5 : 0.5; }

    return SizedBox(
      width: width,
      height: height * max(bs, 0.15),
      child: CustomPaint(
        painter: _AlmondEyePainter(
          eyeWhite: _eyeWhite,
          irisColor: _irisColor,
          blinkValue: bs,
          lookX: lx,
          lookY: ly,
          isRight: isRight,
        ),
      ),
    );
  }

  Widget _buildNose(double headW) {
    return SizedBox(
      width: headW * 0.15,
      height: headW * 0.1,
      child: CustomPaint(
        painter: _NosePainter(color: _skinDark.withOpacity(0.35)),
      ),
    );
  }

  Widget _buildMouth(double w) {
    if (widget.isSpeaking) {
      final open = _mouthCtrl.value;
      return Container(
        width: w * (0.5 + open * 0.4),
        height: w * (0.12 + open * 0.4),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1810),
          borderRadius: BorderRadius.circular(w * 0.25),
          border: Border.all(color: _lipColor, width: 2),
        ),
        child: open > 0.4
            ? Stack(
                children: [
                  Positioned(
                    top: 1,
                    left: w * 0.06,
                    right: w * 0.06,
                    child: Container(
                      height: w * 0.06,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              )
            : null,
      );
    }

    if (widget.emotion.concern > 0.5) {
      return CustomPaint(
        size: Size(w, w * 0.3),
        painter: _FeminineLipPainter(curve: -0.08, color: _lipColor, darkColor: _lipDark),
      );
    }

    final curve = 0.06 + widget.emotion.happiness * 0.2;
    return CustomPaint(
      size: Size(w, w * 0.3),
      painter: _FeminineLipPainter(curve: curve, color: _lipColor, darkColor: _lipDark),
    );
  }

  Widget _buildChefHat(double s) {
    final hatW = s * 0.48;
    final hatH = s * 0.3;

    return SizedBox(
      width: hatW,
      height: hatH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Hat band
          Positioned(
            bottom: 0,
            child: Container(
              width: hatW * 0.9,
              height: hatH * 0.2,
              decoration: BoxDecoration(
                color: _hatBand,
                borderRadius: BorderRadius.circular(3),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                ),
              ),
            ),
          ),
          // Hat puff
          Positioned(
            bottom: hatH * 0.17,
            child: Container(
              width: hatW * 0.95,
              height: hatH * 0.83,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_hatWhite, _hatShadow],
                  stops: const [0.3, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(hatW * 0.4),
                  topRight: Radius.circular(hatW * 0.4),
                  bottomLeft: Radius.circular(hatW * 0.08),
                  bottomRight: Radius.circular(hatW * 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Hat creases
                  Positioned(
                    top: hatH * 0.2,
                    left: hatW * 0.15,
                    child: Container(width: hatW * 0.12, height: 1.5,
                        color: Colors.grey.withOpacity(0.12)),
                  ),
                  Positioned(
                    top: hatH * 0.35,
                    right: hatW * 0.18,
                    child: Container(width: hatW * 0.1, height: 1.5,
                        color: Colors.grey.withOpacity(0.08)),
                  ),
                  Positioned(
                    top: hatH * 0.15,
                    right: hatW * 0.25,
                    child: Container(width: hatW * 0.08, height: 1.5,
                        color: Colors.grey.withOpacity(0.06)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    IconData ic; Color c; bool show = true; bool glow = false;

    switch (widget.state) {
      case CharacterState.listening: ic = Icons.mic; c = Colors.red; glow = true;
      case CharacterState.thinking: ic = Icons.more_horiz; c = Colors.orange; glow = true;
      case CharacterState.celebrating: ic = Icons.celebration; c = Colors.amber;
      case CharacterState.error: ic = Icons.warning_amber_rounded; c = Colors.redAccent;
      case CharacterState.talking: ic = Icons.volume_up; c = Colors.green; glow = true;
      default: show = false; ic = Icons.circle; c = Colors.transparent;
    }

    if (!show) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: c.withOpacity(glow ? _pulse.value * 0.4 : 0.15),
          blurRadius: glow ? 8 : 3, spreadRadius: glow ? 2 : 0,
        )],
      ),
      child: Icon(ic, color: c, size: 13),
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────

class _EyebrowPainter extends CustomPainter {
  final Color color;
  final bool flip;
  final bool worried;

  _EyebrowPainter({required this.color, required this.flip, required this.worried});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (flip) {
      path.moveTo(size.width * 0.1, size.height * (worried ? 0.2 : 0.6));
      path.quadraticBezierTo(
        size.width * 0.5, size.height * (worried ? 0.8 : 0.0),
        size.width * 0.95, size.height * 0.4,
      );
    } else {
      path.moveTo(size.width * 0.05, size.height * 0.4);
      path.quadraticBezierTo(
        size.width * 0.5, size.height * (worried ? 0.8 : 0.0),
        size.width * 0.9, size.height * (worried ? 0.2 : 0.6),
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EyebrowPainter old) => worried != old.worried;
}

class _AlmondEyePainter extends CustomPainter {
  final Color eyeWhite;
  final Color irisColor;
  final double blinkValue;
  final double lookX;
  final double lookY;
  final bool isRight;

  _AlmondEyePainter({
    required this.eyeWhite,
    required this.irisColor,
    required this.blinkValue,
    required this.lookX,
    required this.lookY,
    required this.isRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height * blinkValue;
    if (h < 1) return;

    final center = Offset(w / 2, size.height / 2);

    // Almond eye shape
    final eyePath = Path();
    eyePath.moveTo(w * 0.0, center.dy);
    eyePath.quadraticBezierTo(w * 0.25, center.dy - h * 0.6, w * 0.5, center.dy - h * 0.5);
    eyePath.quadraticBezierTo(w * 0.75, center.dy - h * 0.6, w * 1.0, center.dy);
    eyePath.quadraticBezierTo(w * 0.75, center.dy + h * 0.5, w * 0.5, center.dy + h * 0.45);
    eyePath.quadraticBezierTo(w * 0.25, center.dy + h * 0.5, w * 0.0, center.dy);
    eyePath.close();

    // White
    canvas.drawPath(eyePath, Paint()..color = eyeWhite);

    // Outline
    canvas.drawPath(eyePath, Paint()
      ..color = const Color(0xFF1A1008).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    if (blinkValue > 0.3) {
      // Iris
      final irisR = h * 0.38;
      final irisCx = center.dx + lookX * 1.5;
      final irisCy = center.dy + lookY * 0.8;

      canvas.save();
      canvas.clipPath(eyePath);

      canvas.drawCircle(Offset(irisCx, irisCy), irisR,
          Paint()..color = irisColor);

      // Pupil
      canvas.drawCircle(Offset(irisCx, irisCy), irisR * 0.5,
          Paint()..color = Colors.black);

      // Light reflection
      canvas.drawCircle(
        Offset(irisCx + irisR * 0.25, irisCy - irisR * 0.25),
        irisR * 0.2,
        Paint()..color = Colors.white.withOpacity(0.85),
      );

      canvas.restore();

      // Eyeliner — subtle line on top
      final linerPath = Path();
      linerPath.moveTo(w * 0.02, center.dy);
      linerPath.quadraticBezierTo(w * 0.25, center.dy - h * 0.65, w * 0.5, center.dy - h * 0.55);
      linerPath.quadraticBezierTo(w * 0.75, center.dy - h * 0.65, w * 0.98, center.dy - h * 0.1);
      canvas.drawPath(linerPath, Paint()
        ..color = const Color(0xFF1A1008).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_AlmondEyePainter old) =>
      blinkValue != old.blinkValue || lookX != old.lookX || lookY != old.lookY;
}

class _NosePainter extends CustomPainter {
  final Color color;
  _NosePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.7,
        size.width * 0.7, size.height);
    path.lineTo(size.width * 0.3, size.height);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.7,
        size.width * 0.5, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NosePainter old) => false;
}

class _FeminineLipPainter extends CustomPainter {
  final double curve;
  final Color color;
  final Color darkColor;

  _FeminineLipPainter({required this.curve, required this.color, required this.darkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Upper lip with cupid's bow
    final upperFill = Paint()..color = color..style = PaintingStyle.fill;
    final upperPath = Path();
    upperPath.moveTo(w * 0.1, h * 0.4);
    upperPath.quadraticBezierTo(w * 0.3, h * 0.15, w * 0.45, h * 0.3);
    upperPath.lineTo(w * 0.5, h * 0.25);
    upperPath.lineTo(w * 0.55, h * 0.3);
    upperPath.quadraticBezierTo(w * 0.7, h * 0.15, w * 0.9, h * 0.4);
    upperPath.quadraticBezierTo(w * 0.5, h * (0.5 + curve * 0.5), w * 0.1, h * 0.4);
    upperPath.close();
    canvas.drawPath(upperPath, upperFill);

    // Lower lip
    final lowerFill = Paint()..color = darkColor..style = PaintingStyle.fill;
    final lowerPath = Path();
    lowerPath.moveTo(w * 0.1, h * 0.4);
    lowerPath.quadraticBezierTo(w * 0.5, h * (0.5 + curve * 0.5), w * 0.9, h * 0.4);
    lowerPath.quadraticBezierTo(w * 0.5, h * (0.4 + curve * 3.5), w * 0.1, h * 0.4);
    lowerPath.close();
    canvas.drawPath(lowerPath, lowerFill);

    // Lip shine
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.45, h * 0.32), width: w * 0.12, height: h * 0.06),
      Paint()..color = Colors.white.withOpacity(0.15),
    );
  }

  @override
  bool shouldRepaint(_FeminineLipPainter old) => curve != old.curve;
}