/// Represents the state of the 3D character mascot.
///
/// The character reacts to conversation state — it thinks when processing,
/// talks when speaking, celebrates on success, etc.
enum CharacterState {
  /// Default resting state with idle animation (breathing, blinking)
  idle,

  /// Listening to user (ear-tilting, attentive pose)
  listening,

  /// Processing/thinking (looking up, hand on chin)
  thinking,

  /// Speaking the response (lip-sync active, gesturing)
  talking,

  /// Celebrating a successful action (little dance, thumbs up)
  celebrating,

  /// Something went wrong (worried expression, apologetic gesture)
  error,

  /// Waiting for user confirmation (expectant look, slight lean forward)
  waitingConfirmation,
}

/// Defines a viseme (mouth shape) for lip-sync animation.
class Viseme {
  /// Viseme type (A, B, C, D, E, F, G, H, X for silence)
  final String shape;

  /// Time offset in milliseconds from start of speech
  final int timeMs;

  /// Duration this viseme should hold in milliseconds
  final int durationMs;

  /// Blend weight (0.0 to 1.0)
  final double weight;

  const Viseme({
    required this.shape,
    required this.timeMs,
    required this.durationMs,
    this.weight = 1.0,
  });
}

/// Configuration for the 3D character widget.
class CharacterConfig {
  /// Path or URL to the GLB/glTF 3D model file.
  final String modelPath;

  /// Display size of the character widget.
  final double size;

  /// Background color behind the character.
  final int backgroundColor;

  /// Whether to show the character's shadow/reflection.
  final bool showShadow;

  /// Animation speed multiplier.
  final double animationSpeed;

  /// Camera distance from the character.
  final double cameraDistance;

  /// Whether lip-sync is enabled.
  final bool enableLipSync;

  /// Whether idle animations play.
  final bool enableIdleAnimations;

  /// Rotation speed for idle sway (degrees per second).
  final double idleSwaySpeed;

  const CharacterConfig({
    this.modelPath = 'assets/character/mascot.glb',
    this.size = 200,
    this.backgroundColor = 0x00000000, // transparent
    this.showShadow = true,
    this.animationSpeed = 1.0,
    this.cameraDistance = 2.5,
    this.enableLipSync = true,
    this.enableIdleAnimations = true,
    this.idleSwaySpeed = 15.0,
  });
}

/// Emotion data sent with character state changes for blending expressions.
class CharacterEmotion {
  final double happiness; // 0.0 to 1.0
  final double surprise;
  final double concern;
  final double excitement;

  const CharacterEmotion({
    this.happiness = 0.5,
    this.surprise = 0.0,
    this.concern = 0.0,
    this.excitement = 0.0,
  });

  /// Default neutral expression.
  static const neutral = CharacterEmotion();

  /// Happy response (found food, order placed).
  static const happy = CharacterEmotion(happiness: 0.9, excitement: 0.3);

  /// Thinking/processing.
  static const thinking = CharacterEmotion(happiness: 0.3, surprise: 0.1);

  /// Error or apology.
  static const worried = CharacterEmotion(happiness: 0.1, concern: 0.8);

  /// Celebration.
  static const excited = CharacterEmotion(happiness: 1.0, excitement: 1.0);

  /// Waiting for confirmation.
  static const expectant = CharacterEmotion(happiness: 0.5, surprise: 0.3);
}
