import 'package:cloud_firestore/cloud_firestore.dart';

/// Strict reader for a Firestore wire map. A missing or wrongly typed required
/// field throws a [FormatException] that names the entity and the field.
final class WireReader {
  const WireReader(this.entity, this.map);

  final String entity;
  final Map<String, dynamic> map;

  String string(String field) => _required<String>(field, 'a string');

  String? optionalString(String field) => _optional<String>(field, 'a string');

  int integer(String field) => _required<num>(field, 'a number').toInt();

  double decimal(String field) => _required<num>(field, 'a number').toDouble();

  bool boolean(String field) => _required<bool>(field, 'a boolean');

  DateTime dateTime(String field) =>
      _required<Timestamp>(field, 'a timestamp').toDate();

  DateTime? optionalDateTime(String field) =>
      _optional<Timestamp>(field, 'a timestamp')?.toDate();

  List<String> stringList(String field) =>
      _required<List<dynamic>>(field, 'a list').cast<String>();

  List<Map<String, dynamic>> mapList(String field) =>
      _required<List<dynamic>>(field, 'a list')
          .cast<Map<dynamic, dynamic>>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

  T enumValue<T>(String field, T Function(String key) fromKey) =>
      fromKey(string(field));

  T? optionalEnum<T>(String field, T Function(String key) fromKey) {
    final key = optionalString(field);
    return key == null ? null : fromKey(key);
  }

  T _required<T>(String field, String expected) {
    final value = map[field];
    if (value is T) return value;
    throw FormatException('$entity.$field must be $expected, got $value');
  }

  T? _optional<T>(String field, String expected) {
    final value = map[field];
    if (value == null) return null;
    if (value is T) return value;
    throw FormatException('$entity.$field must be $expected or null');
  }
}

/// Explicit `null` for an absent value: the rules check exact key sets, so keys
/// are never omitted.
Timestamp? timestampOrNull(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
