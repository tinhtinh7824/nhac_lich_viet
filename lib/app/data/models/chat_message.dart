class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
  });

  // Helper constructors
  ChatMessage.user({
    required String content,
    ChatMessageType type = ChatMessageType.text,
  }) : this(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
          type: type,
        );

  ChatMessage.ai({
    required String content,
    ChatMessageType type = ChatMessageType.text,
  }) : this(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          isUser: false,
          timestamp: DateTime.now(),
          type: type,
        );
}

enum ChatMessageType {
  text,
  suggestion,
  greeting,
}