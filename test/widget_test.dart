import 'package:flutter_test/flutter_test.dart';

import 'package:journey/app/app.dart';
import 'package:journey/app/app_scope.dart';

void main() {
  testWidgets('first launch boots through splash into the assessment intro', (tester) async {
    await tester.pumpWidget(JourneyApp(deps: AppDependencies.mock(latency: Duration.zero)));

    expect(find.text('Journey'), findsOneWidget);

    // Mock Python start delay (1.2s) + repository round-trips.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hi there!'), findsOneWidget);
    expect(find.text('Let\'s go'), findsOneWidget);
  });
}
