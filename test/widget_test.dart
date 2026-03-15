import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tachtechlabscom/main.dart';

void main() {
  testWidgets('App renders correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AttckDashboardApp()));

    // Verify that our title is rendered
    expect(find.text('ATT&CK Coverage Dashboard'), findsWidgets);
  });
}
