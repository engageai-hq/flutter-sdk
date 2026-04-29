/// User context that the host app provides to help the AI make better decisions.
class EngageUserContext {
  final String userId;
  final String? displayName;
  final Map<String, dynamic> data;

  const EngageUserContext({
    required this.userId,
    this.displayName,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      'data': data,
    };
  }
}
