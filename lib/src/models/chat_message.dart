/// Represents a single message in the chat UI.
class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isConfirmation;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isConfirmation = false,
  });

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      sender: sender,
      timestamp: timestamp,
      status: status ?? this.status,
      isConfirmation: isConfirmation,
    );
  }
}

enum MessageSender {
  user,
  agent,
  system,
}

enum MessageStatus {
  sending,
  sent,
  error,
}
