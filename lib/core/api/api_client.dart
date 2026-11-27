import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  // Dirección donde corre tu backend Flask en local (puerto 3000)
  final String baseUrl = 'http://127.0.0.1:3000';

  // Cabeceras estándar para enviar y recibir JSON
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  // 1. GET: Consultar listas de datos (ej: /estudiantes, /docentes)
  Future<List<dynamic>> getList(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data;
        } else {
          throw Exception(
            'La respuesta del servidor no tiene formato de lista',
          );
        }
      } else {
        throw Exception(
          'El servidor respondió con código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar con la API: $e');
    }
  }

  // 2. POST: Crear un nuevo registro
  Future<void> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Error al crear registro: código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error en petición POST: $e');
    }
  }

  // 3. PUT: Actualizar un registro existente
  Future<void> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(url, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Error al actualizar registro: código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error en petición PUT: $e');
    }
  }

  // 4. DELETE: Eliminar un registro
  Future<void> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Error al eliminar registro: código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error en petición DELETE: $e');
    }
  }
}
