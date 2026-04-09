/// EngageAI SDK
///
/// Add AI-powered voice and text interaction to any Flutter app.
library engageai_sdk;

// Core
export 'src/core/engageai.dart';
export 'src/core/engageai_config.dart';

// Models
export 'src/models/app_function.dart';
export 'src/models/agent_action.dart';
export 'src/models/chat_message.dart';
export 'src/models/function_manifest.dart';
export 'src/models/user_context.dart';
export 'src/models/character_model.dart';

// Services
export 'src/services/api_client.dart';
export 'src/services/voice_service.dart';
export 'src/services/audio_service.dart';
export 'src/services/streaming_service.dart';

// Widgets
export 'src/widgets/engage_chat_widget.dart';
export 'src/widgets/engage_chat_bubble.dart';
export 'src/widgets/engage_character_widget.dart';
export 'src/widgets/engage_voice_chat_widget.dart';
export 'src/widgets/engage_character_fab.dart';