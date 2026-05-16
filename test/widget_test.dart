import 'package:flutter_test/flutter_test.dart';
import 'package:print_shop_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PrintShopApp());
    await tester.pumpAndSettle();

    expect(find.text('打印店记账'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
  });
}
