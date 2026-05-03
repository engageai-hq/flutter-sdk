/// Marks a function for inclusion in the EngageAI manifest when running
/// `engageai sync --flutter`.
///
/// Example:
/// ```dart
/// /// @engageai Place a food order for the user
/// /// @param restaurantId - The restaurant to order from
/// /// @param items - List of items with quantity
/// /// @engageai-confirm
/// Future<Map<String, dynamic>> placeOrder(String restaurantId, List items) async {
///   // ...
/// }
/// ```
class EngageAIFunction {
  final String description;
  const EngageAIFunction(this.description);
}

/// Marks a function parameter for the EngageAI manifest.
class EngageAIParam {
  final String name;
  final String description;
  const EngageAIParam(this.name, this.description);
}

/// Marks a function as requiring explicit user confirmation before execution.
class EngageAIConfirm {
  const EngageAIConfirm();
}

// Convenience instance for the confirm annotation
const engageAIConfirm = EngageAIConfirm();
