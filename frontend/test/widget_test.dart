import 'package:flutter_test/flutter_test.dart';
import 'package:magadi_awfar/main.dart';

void main() {
  testWidgets('App renders Arabic home screen with search and district', (WidgetTester tester) async {
    await tester.pumpWidget(const MagadiAwfarApp());
    await tester.pump();

    // Verify app brand is rendered
    expect(find.text('مقاضي أوفر'), findsOneWidget);
    expect(find.text('مقارنة الأسعار'), findsOneWidget);
    expect(find.text('السلة الصوتية'), findsOneWidget);
    expect(find.text('سلة المقاضي'), findsOneWidget);
  });
}
