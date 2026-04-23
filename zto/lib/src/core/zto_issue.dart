/// A single validation failure for one field or the DTO as a whole.
class ZtoIssue {
  const ZtoIssue({required this.message, this.field});

  /// Human-readable error message.
  final String message;

  /// The JSON key of the failing field, or `null` for DTO-level issues.
  final String? field;

  Map<String, dynamic> toMap() => {
        if (field != null) 'field': field,
        'message': message,
      };
}
