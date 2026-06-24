import 'api_client.dart' as client;

/// Backwards compatible mock database service.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  bool get isInitialized => true;
  void markInitialized() {}
  Future<void> close() async {}
}

Map<String, String?> rowToMap(dynamic row) {
  if (row is Map) {
    return Map<String, String?>.from(
      row.map((key, val) => MapEntry(key.toString(), val?.toString())),
    );
  }
  return {};
}

DateTime parseDate(String? value, [DateTime? fallback]) => client.parseDate(value, fallback);
String dateOnly(DateTime dt) => client.dateOnly(dt);
