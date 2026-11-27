import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  // Dirección donde corre tu backend Flask en local (puerto 3000)
  final String baseUrl = 'http://127.0.0.1:3000';

  // Función genérica para consultar listas de datos
  // Recibe la ruta específica, por ejemplo: '/estudiantes' o '/docentes'
  Future<List<dynamic>> getList(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // utf8.decode permite que nombres con tildes o 'ñ' se lean correctamente
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
}
