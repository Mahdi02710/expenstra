import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';
  final String _baseUrl;

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _getIdToken();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    return _handleResponse(response);
  }

  Future<dynamic> get(String path) async {
    final token = await _getIdToken();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    return _handleResponse(response);
  }

  Future<int> getStatus(String path) async {
    final token = await _getIdToken();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    return response.statusCode;
  }

  Future<dynamic> delete(String path) async {
    final token = await _getIdToken();
    final response = await http
        .delete(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    return _handleResponse(response);
  }

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get ID token');
    }
    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    }
    throw Exception('API error ${response.statusCode}: ${response.body}');
  }
}
