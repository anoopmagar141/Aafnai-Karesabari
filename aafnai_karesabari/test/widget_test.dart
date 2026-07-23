import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_karesabari/app.dart';

void main() {
  testWidgets('starts on the branded splash screen', (tester) async {
    await tester.pumpWidget(const HamroKaresabariApp());

    expect(find.text('Hamro Karesabari'), findsOneWidget);
    expect(find.text('From local farms to your home'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Choose your language'), findsOneWidget);
  });
}
