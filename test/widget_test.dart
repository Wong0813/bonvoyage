import 'package:flutter_test/flutter_test.dart';
import 'package:bonvoyage/main.dart';

void main() {
  testWidgets('BonVoyage app loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BonVoyageApp());
    await tester.pump();
    expect(find.text('BonVoyage'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
