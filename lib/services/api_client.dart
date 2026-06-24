import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) async {
    Uri uri = Uri.parse('$baseUrl$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final response = await http.get(uri);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, dynamic body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, dynamic body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {dynamic body}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: body != null ? {'Content-Type': 'application/json'} : null,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      Map<String, dynamic> errorMap;
      try {
        errorMap = jsonDecode(response.body);
      } catch (_) {
        errorMap = {'error': response.reasonPhrase};
      }
      throw Exception(errorMap['error'] ?? 'API error: ${response.statusCode}');
    }
  }
}

DateTime parseDate(String? value, [DateTime? fallback]) {
  if (value == null || value.isEmpty) return fallback ?? DateTime.now();
  try {
    return DateTime.parse(value);
  } catch (_) {
    return fallback ?? DateTime.now();
  }
}

String dateOnly(DateTime dt) => dt.toIso8601String().split('T').first;
