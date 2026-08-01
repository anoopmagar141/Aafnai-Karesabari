import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_karesabari/app.dart';

import 'firebase_test_helper.dart';

void main() {
  setUpAll(setupFirebaseForTests);

  testWidgets('starts on the branded splash screen', (tester) async {
    await tester.pumpWidget(const HamroKaresabariApp());

    expect(find.text('Hamro Karesabari'), findsOneWidget);
    expect(find.textContaining('From local farms to your home'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
