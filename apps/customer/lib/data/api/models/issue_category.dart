// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum IssueCategory {
  /// The name has been replaced because it contains a keyword. Original name: `LATE`.
  @JsonValue('LATE')
  valueLate('LATE'),
  @JsonValue('MISSED_PICKUP')
  missedPickup('MISSED_PICKUP'),
  @JsonValue('DAMAGED')
  damaged('DAMAGED'),
  @JsonValue('MISSING_ITEM')
  missingItem('MISSING_ITEM'),
  @JsonValue('QUALITY')
  quality('QUALITY'),
  @JsonValue('BILLING')
  billing('BILLING'),
  @JsonValue('RIDER')
  rider('RIDER'),
  @JsonValue('OTHER')
  other('OTHER'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const IssueCategory(this.json);

  factory IssueCategory.fromJson(String json) => values.firstWhere(
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
  static List<IssueCategory> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
