/// Configuration for the EngageAI SDK.
class EngageAIConfig {
  /// URL of the EngageAI backend server.
  final String serverUrl;

  /// Unique identifier for your app (must match your registered manifest).
  final String appId;

  /// Your app's display name.
  final String appName;

  /// Optional API key for authentication with the EngageAI server.
  final String? apiKey;

  /// App domain category.
  final String domain;

  /// App description (helps the AI understand your app).
  final String description;

  /// Connection timeout in seconds.
  final int timeoutSeconds;

  /// Language code for voice recognition (e.g., 'en', 'fr', 'es', 'yo', 'ha', 'ig', 'ar')
  final String language;

  /// Whether to enable debug logging.
  final bool debug;

  const EngageAIConfig({
    required this.serverUrl,
    required this.appId,
    required this.appName,
    this.apiKey,
    this.domain = 'other',
    this.description = '',
    this.timeoutSeconds = 30,
    this.language = 'en',
    this.debug = false,
  });
}