import 'zto_exception.dart';

/// Adds [refine] to **any** value, so cross-field / business-rule validation can
/// be chained right after [ZtoSchema.parse] / [Zto.parse] without requiring the
/// [ZtoDto] mixin on the parsed class.
///
/// ```dart
/// final dto = $CreateOrderRequestDtoSchema
///     .parse(body, CreateOrderRequestDto.fromMap)
///     .refine(
///       (d) => d.order.paymentType != PaymentType.unknown,
///       field: 'order.payment_type',
///       message: 'payment_type is required',
///     );
/// ```
///
/// Returns the value unchanged when [predicate] holds; otherwise throws a
/// [ZtoException] (mapped to HTTP 422 by the request guards).
///
/// Classes that mix in [ZtoDto] keep using the mixin's `refine` (instance
/// members win over extension members) — this extension only covers the types
/// that don't.
extension ZtoRefineExtension<T> on T {
  T refine(
    bool Function(T value) predicate, {
    required String message,
    String? field,
  }) {
    if (predicate(this)) return this;
    throw ZtoException(
      message: 'Validation failed',
      issues: [ZtoIssue(message: message, field: field)],
    );
  }
}
