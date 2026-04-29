/// Defines a function that the host app exposes to EngageAI.
///
/// The [handler] is called by the SDK when the AI agent decides this
/// function should be executed.
class AppFunction {
  /// Unique function name (snake_case).
  final String name;

  /// Clear description of what this function does. The AI reads this
  /// to decide when to call it — be descriptive!
  final String description;

  /// Parameter schema as a Map matching JSON Schema format.
  final Map<String, dynamic> parameters;

  /// The actual function to execute. Receives parameters from the AI,
  /// returns a result that gets sent back to the agent.
  final Future<dynamic> Function(Map<String, dynamic> params) handler;

  /// Whether this function requires explicit user confirmation.
  final bool requiresConfirmation;

  /// Whether this function requires an authenticated user.
  final bool requiresAuth;

  /// Side effects of this function (e.g., 'charges_money').
  final List<String> sideEffects;

  /// Example natural language phrases that trigger this function.
  final List<String> examples;

  /// Return type schema (optional, for documentation).
  final Map<String, dynamic>? returns;

  const AppFunction({
    required this.name,
    required this.description,
    required this.parameters,
    required this.handler,
    this.requiresConfirmation = false,
    this.requiresAuth = false,
    this.sideEffects = const ['none'],
    this.examples = const [],
    this.returns,
  });

  /// Convert to the manifest format for server registration.
  Map<String, dynamic> toManifestJson() {
    return {
      'name': name,
      'description': description,
      'parameters': parameters,
      if (returns != null) 'returns': returns,
      'requires_confirmation': requiresConfirmation,
      'requires_auth': requiresAuth,
      'side_effects': sideEffects,
      'examples': examples,
    };
  }
}
