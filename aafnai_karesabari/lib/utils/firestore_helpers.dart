import 'package:cloud_firestore/cloud_firestore.dart';

/// Small null-safe converters between Dart types and Firestore's wire
/// format (Timestamp, num). NOTE: a near-duplicate of this file also
/// exists at lib/data/models/firestore_helpers.dart — different models
/// import different copies, so keep both in mind if these need a fix.
///
/// Converts a non‑null Firestore [Timestamp] to a [DateTime].
DateTime timestampFromFirestoreRequired(Object? timestamp) =>
    timestamp is DateTime ? timestamp : (timestamp as Timestamp).toDate();

/// Converts a nullable Firestore [Timestamp] to a [DateTime] or null.
DateTime? timestampFromFirestore(Object? timestamp) {
  if (timestamp == null) return null;
  return timestamp is DateTime ? timestamp : (timestamp as Timestamp).toDate();
}

/// Converts a [DateTime] to a Firestore [Timestamp].
Object timestampToFirestore(DateTime date) => Timestamp.fromDate(date);

/// Converts a nullable [DateTime] to a Firestore [Timestamp] or null.
Object? timestampToFirestoreNullable(DateTime? date) =>
    date == null ? null : Timestamp.fromDate(date);

/// Safely parses a double from a Firestore field that might be null or a number.
double doubleFromFirestore(Object? value) =>
    (value as num?)?.toDouble() ?? 0.0;

/// Safely parses an integer from a Firestore field that might be null or a number.
int intFromFirestore(Object? value) => (value as num?)?.toInt() ?? 0;
