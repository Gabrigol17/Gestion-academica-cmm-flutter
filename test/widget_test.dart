import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_academica_cmm_flutter/app.dart';
import 'package:gestion_academica_cmm_flutter/core/api/api_client.dart';

void main() {
  testWidgets('Carga inicial de HomePage', (WidgetTester tester) async {
    final apiClient = ApiClient();
    await tester.pumpWidget(MyApp(apiClient: apiClient));
    expect(find.text('Gestión Académica CMM'), findsOneWidget);
    expect(find.text('Estudiantes'), findsOneWidget);
  });
}
