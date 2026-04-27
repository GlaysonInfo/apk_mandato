import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gabinete_ia_mobile/app.dart';

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GabineteApp()));

    expect(find.text('Cadastro de Campo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
