/// The function manifest built on the client side and sent to the server.
class FunctionManifest {
  final String appId;
  final String appName;
  final String version;
  final String description;
  final String domain;
  final List<Map<String, dynamic>> functions;
  final Map<String, dynamic>? confirmationRules;
  final Map<String, dynamic>? authentication;

  const FunctionManifest({
    required this.appId,
    required this.appName,
    this.version = '1.0.0',
    this.description = '',
    this.domain = 'other',
    this.functions = const [],
    this.confirmationRules,
    this.authentication,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_id': appId,
      'app_name': appName,
      'version': version,
      'description': description,
      'domain': domain,
      'functions': functions,
      if (confirmationRules != null) 'confirmation_rules': confirmationRules,
      if (authentication != null) 'authentication': authentication,
    };
  }
}
