/// The single exception type raised by repository/service calls (e.g. a
/// failed Firestore request) so callers can catch one type and show
/// `message` directly to the user, or fall back to a local data source.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
