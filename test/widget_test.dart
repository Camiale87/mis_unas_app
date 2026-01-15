import 'package:flutter_test/flutter_test.dart';
import 'package:mis_unas_app/main.dart'; 

void main() {
  testWidgets('Prueba de carga del catálogo de uñas', (WidgetTester tester) async {
    // 1. Carga la aplicación (Nombre corregido sin tilde)
    await tester.pumpWidget(const MiSalonApp());

    // 2. Verifica que el título del App Bar sea el correcto
    expect(find.text('NAIL ART STUDIO'), findsOneWidget);

    // 3. Verifica que encuentre un diseño de la lista
    expect(find.text('Soft Gel Natural'), findsOneWidget);

    // 4. Verifica que ya no busque el '0' del contador viejo
    expect(find.text('0'), findsNothing);
  });
}