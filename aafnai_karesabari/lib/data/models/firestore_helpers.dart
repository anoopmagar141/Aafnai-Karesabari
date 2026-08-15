import 'package:cloud_firestore/cloud_firestore.dart';

/// Small null-safe converters between Dart types and Firestore's wire
/// format (Timestamp, num), used by every model's `fromMap`/`toFirestore`.
///
/// Converts a non‑null Firestore [Timestamp] to a [DateTime].
DateTime timestampFromFirestoreRequired(Object? timestamp) =>
    (timestamp as Timestamp).toDate();

/// Converts a nullable Firestore [Timestamp] to a [DateTime] or returns null.
DateTime? timestampFromFirestore(Object? timestamp) =>
    timestamp == null ? null : (timestamp as Timestamp).toDate();

/// Converts a [DateTime] to a Firestore [Timestamp].
Object timestampToFirestore(DateTime date) => Timestamp.fromDate(date);

/// Converts a nullable [DateTime] to a Firestore [Timestamp] or null.
Object? timestampToFirestoreNullable(DateTime? date) =>
    date == null ? null : Timestamp.fromDate(date);

/// Safely parses an integer from a Firestore field that might be null or a number.
int intFromFirestore(Object? value) => (value as num?)?.toInt() ?? 0;

/// Safely parses a double from a Firestore field that might be null or a number.
double doubleFromFirestore(Object? value) => (value as num?)?.toDouble() ?? 0.0;

/// Safely parses a list of strings from a Firestore field that might be null or a List.
List<String> stringListFromFirestore(Object? value) =>
    (value as List?)?.cast<String>() ?? const [];
