import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';

void main() {
  final apiClient = ApiClient();
  runApp(MyApp(apiClient: apiClient));
}
