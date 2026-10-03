// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Why the promo code was not applied, if it was not.
@JsonEnum()
enum QuoteDtoPromoError {
  @JsonValue('PROMO_NOT_FOUND')
  promoNotFound('PROMO_NOT_FOUND'),
  @JsonValue('PROMO_EXPIRED')
  promoExpired('PROMO_EXPIRED'),
  @JsonValue('PROMO_LIMIT_REACHED')
  promoLimitReached('PROMO_LIMIT_REACHED'),
  @JsonValue('PROMO_MIN_ORDER')
  promoMinOrder('PROMO_MIN_ORDER'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const QuoteDtoPromoError(this.json);

  factory QuoteDtoPromoError.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError('Cannot convert enum value with null JSON representation to String. '
          'This usually happens for \$unknown or @JsonValue(null) entries.');
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<QuoteDtoPromoError> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
