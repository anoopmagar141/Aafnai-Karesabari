import 'package:cloud_firestore/cloud_firestore.dart';

/// Parses Firestore [Timestamp], epoch milliseconds, or [DateTime] values.
DateTime? timestampFromFirestore(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }
  if (value is DateTime) return value;
  return null;
}

DateTime timestampFromFirestoreRequired(Object? value) {
  return timestampFromFirestore(value) ?? DateTime.now();
}

Object timestampToFirestore(DateTime value) => Timestamp.fromDate(value.toLocal());

Object? timestampToFirestoreNullable(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value.toLocal());
}

List<String> stringListFromFirestore(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

double doubleFromFirestore(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return fallback;
}

int intFromFirestore(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return fallback;
}
