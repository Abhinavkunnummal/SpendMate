import 'package:flutter_test/flutter_test.dart';
import 'package:spendmate/main.dart';
import 'package:spendmate/core/theme/app_colors.dart';

void main() {
  testWidgets('SpendMate App boots and shows Welcome Branding', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendMateApp());
    await tester.pumpAndSettle();

    // Verify SpendMate logo brand tag exists
    expect(find.text('SpendMate'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
