import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_academica_cmm_flutter/app.dart';

void main() {
  testWidgets('Carga inicial de HomePage', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Gestión Académica CMM'), findsOneWidget);
    expect(find.text('Estudiantes'), findsOneWidget);
  });
}
