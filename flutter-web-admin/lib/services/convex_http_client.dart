import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente HTTP para Convex — reemplaza convex_flutter
/// Usa la HTTP API estable de Convex en vez de WebSocket
class ConvexHttpClient {
  final String deploymentUrl;
  String? _authToken;

  ConvexHttpClient({
    required this.deploymentUrl,
  });

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Ejecuta una mutation
  Future<dynamic> mutation(String path, Map<String, dynamic> args) async {
    final uri = Uri.parse('$deploymentUrl/api/mutation');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'path': path, 'args': [args]}),
    );
    return _handleResponse(response, 'mutation $path');
  }

  /// Ejecuta un query
  Future<dynamic> query(String path, Map<String, dynamic> args) async {
    final uri = Uri.parse('$deploymentUrl/api/query');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'path': path, 'args': [args]}),
    );
    return _handleResponse(response, 'query $path');
  }

  /// Ejecuta una action
  Future<dynamic> action(String path, Map<String, dynamic> args) async {
    final uri = Uri.parse('$deploymentUrl/api/action');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'path': path, 'args': [args]}),
    );
    return _handleResponse(response, 'action $path');
  }

  dynamic _handleResponse(http.Response response, String label) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('errorMessage')) {
        throw ConvexException(data['errorMessage'], label);
      }
      return data['value'] ?? data;
    }
    // 400 con error de Convex
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('errorMessage')) {
        throw ConvexException(data['errorMessage'], label);
      }
    } catch (_) {}
    throw ConvexException('HTTP ${response.statusCode}: ${response.body}', label);
  }
}

class ConvexException implements Exception {
  final String message;
  final String operation;
  ConvexException(this.message, this.operation);
  @override
  String toString() => '[Convex] $operation: $message';
}
