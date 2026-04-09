/// Types of actions the agent can take.
enum AgentActionType {
  respond,
  functionCall,
  confirm,
  clarify,
  error,
}

/// A function call the agent wants to execute.
class FunctionCallRequest {
  final String functionName;
  final Map<String, dynamic> arguments;
  final String callId;

  const FunctionCallRequest({
    required this.functionName,
    this.arguments = const {},
    this.callId = '',
  });

  factory FunctionCallRequest.fromJson(Map<String, dynamic> json) {
    return FunctionCallRequest(
      functionName: json['function_name'] as String,
      arguments: Map<String, dynamic>.from(json['arguments'] ?? {}),
      callId: json['call_id'] as String? ?? '',
    );
  }
}

/// The agent's response after processing a message.
class AgentAction {
  final AgentActionType actionType;
  final String? message;
  final List<FunctionCallRequest> functionCalls;
  final String? confirmationPrompt;
  final bool requiresInput;

  const AgentAction({
    required this.actionType,
    this.message,
    this.functionCalls = const [],
    this.confirmationPrompt,
    this.requiresInput = false,
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['action_type'] as String;
    final actionType = _parseActionType(typeStr);

    final calls = (json['function_calls'] as List<dynamic>?)
            ?.map((c) => FunctionCallRequest.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return AgentAction(
      actionType: actionType,
      message: json['message'] as String?,
      functionCalls: calls,
      confirmationPrompt: json['confirmation_prompt'] as String?,
      requiresInput: json['requires_input'] as bool? ?? false,
    );
  }

  static AgentActionType _parseActionType(String type) {
    switch (type) {
      case 'respond':
        return AgentActionType.respond;
      case 'function_call':
        return AgentActionType.functionCall;
      case 'confirm':
        return AgentActionType.confirm;
      case 'clarify':
        return AgentActionType.clarify;
      case 'error':
        return AgentActionType.error;
      default:
        return AgentActionType.respond;
    }
  }
}
