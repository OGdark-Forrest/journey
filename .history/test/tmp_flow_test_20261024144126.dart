import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journey/app/app.dart';
import 'package:journey/app/app_scope.dart';
import 'package:journey/shared/widgets/option_tile.dart';

Future<void> settle(WidgetTester t, [int ms = 800]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final size in [const Size(360, 640), const Size(412, 915)]) {
    testWidgets('full flow at $size', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      await t.pumpWidget(JourneyApp(deps: AppDependencies.mock(latency: Duration.zero)));
      await settle(t, 2500);
      await t.tap(find.text('Let\'s go'));
      await settle(t);

      await t.enterText(find.byType(EditableText), 'Sam');
      await settle(t, 300);
      await t.tap(find.text('Continue'));
      await settle(t);

      for (var i = 0; i < 7; i++) {
        final tile = find.byType(OptionTile).first;
        await t.ensureVisible(tile);
        await t.tap(tile);
        await settle(t, 300);
        final next = find.text(i == 6 ? 'Finish' : 'Continue');
        await t.tap(next);
        await settle(t);
      }

      expect(find.text('You\'re all set!'), findsOneWidget);
      await t.tap(find.text('Go to my journal'));
      await settle(t, 1500);

      expect(find.textContaining(', Sam'), findsOneWidget);
      expect(find.text('Log an event'), findsOneWidget);

      // Wake-up: confirm usual.
      await t.tap(find.textContaining('Around'));
      await settle(t);
      expect(find.textContaining('Woke up at'), findsOneWidget);

      // Normal entry -> first of the day -> celebration.
      await t.tap(find.text('Log an event'));
      await settle(t);
      expect(find.text('Save entry'), findsOneWidget);
      await t.tap(find.text('Great').first);
      await settle(t, 300);
      await t.tap(find.text('Save entry'));
      await settle(t);
      expect(find.text('Streak kept!'), findsOneWidget);
      await t.tap(find.text('Continue'));
      await settle(t, 1200);

      // Blitz entry -> snackbar, no celebration.
      await t.tap(find.text('Blitz'));
      await settle(t);
      expect(find.text('Looks right, save'), findsOneWidget);
      await t.tap(find.text('Looks right, save'));
      await settle(t, 1200);
      expect(find.textContaining('2 of 10 today'), findsOneWidget);

      // Settings + dark mode.
      await t.tap(find.byTooltip('Settings'));
      await settle(t);
      expect(find.text('Entries per day'), findsOneWidget);
      await t.tap(find.text('Dark'));
      await settle(t);
      await t.scrollUntilVisible(find.text('Retake initial assessment'), 200);
      await settle(t, 300);
    });
  }
}
