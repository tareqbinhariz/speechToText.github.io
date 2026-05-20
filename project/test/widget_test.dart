import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text_alsady_web/main.dart';

void main() {
  testWidgets('App builds and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Aswat'), findsWidgets);
  });
}
