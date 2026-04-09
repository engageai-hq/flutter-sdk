import 'package:uuid/uuid.dart';

import 'engageai_config.dart';
import '../models/app_function.dart';
import '../models/agent_action.dart';
import '../models/chat_message.dart';
import '../models/function_manifest.dart';
import '../models/user_context.dart';
import '../services/api_client.dart';

/// Main EngageAI SDK class.
///
/// This is the primary interface for integrating EngageAI into your Flutter app.
///
/// ## Usage
/// ```dart
/// final engageAI = EngageAI(
///   config: EngageAIConfig(
///     serverUrl: 'https://your-server.com',
///     appId: 'my_app',
///     appName: 'My App',
///   ),
/// );
///
/// // Register functions your app can perform
/// engageAI.registerFunction(AppFunction(
///   name: 'search_items',
///   description: 'Search for items in the catalog',
///   parameters: {'type': 'object', 'properties': {...}},
///   handler: (params) async => myApi.search(params),
/// ));
///
/// // Initialize (registers manifest with server)
/// await engageAI.initialize();
/// ```
class EngageAI {
  final EngageAIConfig config;
  final EngageAIApiClient _apiClient;
  final Map<String, AppFunction> _functions = {};
  final List<ChatMessage> _messages = [];

  String _sessionId;
  EngageUserContext? _userContext;
  bool _initialized = false;

  /// Callback fired when the agent responds with a message.
  void Function(AgentAction action)? onAgentAction;

  /// Callback fired when a function is being executed.
  void Function(String functionName)? onFunctionExecuting;

  /// Callback fired when the message list changes.
  void Function(List<ChatMessage> messages)? onMessagesChanged;

  EngageAI({required this.config, EngageAIApiClient? apiClient})
      : _apiClient = apiClient ?? EngageAIApiClient(config: config),
        _sessionId = 'sess_${const Uuid().v4().replaceAll('-', '').substring(0, 16)}';

  /// Whether the SDK has been initialized and manifest registered.
  bool get isInitialized => _initialized;

  /// Current session ID.
  String get sessionId => _sessionId;

  /// Current message history.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Register a function that your app can perform.
  ///
  /// Call this for each action your app supports before calling [initialize].
  void registerFunction(AppFunction function_) {
    _functions[function_.name] = function_;
    if (config.debug) {
      print('[EngageAI] Registered function: ${function_.name}');
    }
  }

  /// Register multiple functions at once.
  void registerFunctions(List<AppFunction> functions) {
    for (final fn in functions) {
      registerFunction(fn);
    }
  }

  /// Set the current user context.
  void setUserContext(EngageUserContext context) {
    _userContext = context;
  }

  /// Initialize the SDK by registering the app manifest with the server.
  Future<void> initialize() async {
    if (_functions.isEmpty) {
      throw StateError(
          'No functions registered. Call registerFunction() before initialize().');
    }

    final manifest = FunctionManifest(
      appId: config.appId,
      appName: config.appName,
      description: config.description,
      domain: config.domain,
      functions: _functions.values.map((fn) => fn.toManifestJson()).toList(),
    );

    final success = await _apiClient.registerManifest(manifest.toJson());
    if (!success) {
      throw StateError('Failed to register manifest with EngageAI server');
    }

    _initialized = true;
    if (config.debug) {
      print('[EngageAI] Initialized with ${_functions.length} functions');
    }
  }

  /// Send a text message from the user and process the agent's response.
  ///
  /// This handles the full loop:
  /// 1. Send message to agent
  /// 2. If agent wants to call functions → execute them → send results back
  /// 3. If agent wants confirmation → add confirmation message
  /// 4. If agent responds with text → add to messages
  Future<AgentAction> sendMessage(String text) async {
    _ensureInitialized();

    // Add user message to local history
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _notifyMessagesChanged();

    // Send to server
    final response = await _apiClient.sendMessage(
      sessionId: _sessionId,
      message: text,
      userContext: _userContext,
    );

    // Update session ID (server may have created a new one)
    _sessionId = response.sessionId;

    // Process the agent's action
    return _handleAgentAction(response.action);
  }

  /// Confirm a pending action.
  Future<AgentAction> confirm() async {
    _ensureInitialized();

    _addAgentMessage('Confirmed ✓', isUser: true);

    final response = await _apiClient.sendConfirmation(
      sessionId: _sessionId,
      confirmed: true,
    );

    return _handleAgentAction(response.action);
  }

  /// Deny/cancel a pending action.
  Future<AgentAction> deny() async {
    _ensureInitialized();

    _addAgentMessage('Cancelled ✗', isUser: true);

    final response = await _apiClient.sendConfirmation(
      sessionId: _sessionId,
      confirmed: false,
    );

    return _handleAgentAction(response.action);
  }

  /// Start a new conversation session.
  void resetSession() {
    _sessionId =
        'sess_${const Uuid().v4().replaceAll('-', '').substring(0, 16)}';
    _messages.clear();
    _notifyMessagesChanged();
  }

  /// Process an agent action — execute functions, handle confirmations, etc.
  Future<AgentAction> _handleAgentAction(AgentAction action) async {
    switch (action.actionType) {
      case AgentActionType.respond:
      case AgentActionType.clarify:
      case AgentActionType.error:
        // Just add the message to chat
        if (action.message != null) {
          _addAgentMessage(action.message!);
        }
        onAgentAction?.call(action);
        return action;

      case AgentActionType.confirm:
        // Show confirmation prompt
        if (action.message != null) {
          _messages.add(ChatMessage(
            id: const Uuid().v4(),
            content: action.message!,
            sender: MessageSender.agent,
            timestamp: DateTime.now(),
            isConfirmation: true,
          ));
          _notifyMessagesChanged();
        }
        onAgentAction?.call(action);
        return action;

      case AgentActionType.functionCall:
        // Execute the function(s) and feed results back
        if (action.message != null) {
          _addAgentMessage(action.message!);
        }
        return _executeFunctions(action.functionCalls);
    }
  }

  /// Execute function calls from the agent and send results back.
  Future<AgentAction> _executeFunctions(
      List<FunctionCallRequest> calls) async {
    final results = <Map<String, dynamic>>[];

    for (final call in calls) {
      final fn = _functions[call.functionName];
      if (fn == null) {
        results.add({
          'call_id': call.callId,
          'function_name': call.functionName,
          'success': false,
          'error': 'Function "${call.functionName}" not registered in SDK',
        });
        continue;
      }

      onFunctionExecuting?.call(call.functionName);

      try {
        final result = await fn.handler(call.arguments);
        results.add({
          'call_id': call.callId,
          'function_name': call.functionName,
          'success': true,
          'result': result,
        });
      } catch (e) {
        results.add({
          'call_id': call.callId,
          'function_name': call.functionName,
          'success': false,
          'error': e.toString(),
        });
      }
    }

    // Send results back to agent for further reasoning
    final response = await _apiClient.sendFunctionResults(
      sessionId: _sessionId,
      results: results,
    );

    return _handleAgentAction(response.action);
  }

  void _addAgentMessage(String content, {bool isUser = false}) {
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      content: content,
      sender: isUser ? MessageSender.user : MessageSender.agent,
      timestamp: DateTime.now(),
    ));
    _notifyMessagesChanged();
  }

  void _notifyMessagesChanged() {
    onMessagesChanged?.call(messages);
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'EngageAI not initialized. Call initialize() first.');
    }
  }

  /// Clean up resources.
  void dispose() {
    _apiClient.dispose();
  }
}
