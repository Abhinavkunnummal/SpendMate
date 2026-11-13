import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendmate/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SpendMate App boots and shows Welcome Branding', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpendMateApp()));
    await tester.pumpAndSettle();

    expect(find.text('SpendMate'), findsWidgets);
    expect(find.textContaining('Get Started'), findsOneWidget);
  });
}
