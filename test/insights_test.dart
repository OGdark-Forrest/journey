import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:journey/app/app_scope.dart';
import 'package:journey/app/theme.dart';
import 'package:journey/core/models/goal.dart';
import 'package:journey/core/models/insight.dart';
import 'package:journey/features/insights/recommendations_screen.dart';
import 'package:journey/features/insights/reflection_screen.dart';

// Shaped like a real Gemini answer to the serverRec.py prompts: a preamble,
// bold labels, numbered lists, and a "### Morning" style subheading.
const _reflection = '''
Here's your reflection.

## Goal alignment
- **Walk daily**: you went for a walk at 6:00 PM.
- Work ran long in the afternoon.

## Overall feeling
Happiness score: **7/10**. You started okay and finished great.

## What could have been better
1. Take a break before 3 PM.
2. Put the phone down by 10.
''';

const _plan = '''
## Day plan
### Morning (7-11am)
- Have breakfast
- Morning walk by the river
**Afternoon:**
- Work in two focused blocks
Evening: dinner with a friend

## Goal focus
This should be a **balanced day** rather than a push day.
''';

void main() {
  group('Insight parsing', () {
    test('splits reflection sections and reads the score', () {
      final i = Insight(kind: InsightKind.reflection, day: DateTime(2026, 10, 24), text: _reflection, entryCount: 4);
      expect(i.headedSections.map((s) => s.heading), [
        Insight.goalAlignment,
        Insight.overallFeeling,
        Insight.couldBeBetter,
      ]);
      expect(i.intro?.plainText, 'Here\'s your reflection.');
      expect(i.happinessScore, 7);
      expect(i.section(Insight.couldBeBetter)!.lines.every((l) => l.bullet), isTrue);
      expect(i.isEmpty, isFalse);
    });

    test('groups the day plan and picks the first day type mentioned', () {
      final i = Insight(kind: InsightKind.recommendations, day: DateTime(2026, 10, 25), text: _plan, entryCount: 9);
      expect(i.plan[DayPart.morning], ['Have breakfast', 'Morning walk by the river']);
      expect(i.plan[DayPart.afternoon], ['Work in two focused blocks']);
      expect(i.plan[DayPart.evening], ['dinner with a friend']);
      expect(i.dayType, DayType.balanced);
    });

    test('a sentence with no headings is empty', () {
      final i = Insight(
        kind: InsightKind.reflection,
        day: DateTime(2026, 10, 24),
        text: 'No activity was logged for Friday, October 24, so there\'s nothing to reflect on yet.',
        entryCount: 0,
      );
      expect(i.isEmpty, isTrue);
    });
  });

  group('Mock request', () {
    test('matches the Python InsightRequest shape', () async {
      final deps = AppDependencies.mock(latency: Duration.zero);
      await deps.goals.add(GoalPeriod.daily, 'go for a walk');
      final insight = await deps.insights.reflect(DateTime.now().subtract(const Duration(days: 2)));
      expect(insight.headedSections, hasLength(3));
      expect(insight.happinessScore, isNotNull);
    });
  });

  // The otter's idle animation loops forever, so pumpAndSettle never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<AppDependencies> pumpScreen(WidgetTester tester, Widget screen) async {
    final deps = AppDependencies.mock(latency: Duration.zero);
    await tester.pumpWidget(AppScope(
      deps: deps,
      child: MaterialApp(theme: JourneyTheme.light(), home: screen),
    ));
    return deps;
  }

  testWidgets('reflection: generate, step through, then see everything', (tester) async {
    await pumpScreen(tester, const ReflectionScreen());
    // Seed history has entries 2 days ago.
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    await tester.tap(find.text('${twoDaysAgo.day}'));
    await settle(tester);

    await tester.tap(find.textContaining('Reflect on'));
    await tester.pump();
    expect(find.text('Looking back at your day...'), findsOneWidget);
    await settle(tester);

    expect(find.textContaining('Step 1 of 3'), findsOneWidget);
    expect(find.text(Insight.goalAlignment), findsWidgets);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.textContaining('Step 2 of 3'), findsOneWidget);
    expect(find.text('Happiness score'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.textContaining('Step 3 of 3'), findsOneWidget);
    await tester.tap(find.text('See it all'));
    await settle(tester);
    expect(find.byTooltip('Step through'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Step through again'),
      300,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
    );
    await tester.tap(find.text('Step through again'));
    await settle(tester);
    expect(find.textContaining('Step 1 of 3'), findsOneWidget);
  });

  testWidgets('reflection on a day with no logs shows the empty message', (tester) async {
    await pumpScreen(tester, const ReflectionScreen());
    // Seed history skips 5 days ago.
    final empty = DateTime.now().subtract(const Duration(days: 5));
    await tester.tap(find.text('${empty.day}'));
    await settle(tester);
    await tester.tap(find.textContaining('Reflect on'));
    await settle(tester);
    expect(find.textContaining('nothing to reflect on yet'), findsOneWidget);
  });

  testWidgets('recommendations: plan steps through day plan and goal focus', (tester) async {
    await pumpScreen(tester, const RecommendationsScreen());
    await tester.tap(find.textContaining('Plan '));
    await settle(tester);

    expect(find.textContaining('Step 1 of 2'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.textContaining('Step 2 of 2'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^(Push|Balanced|Rest) day$')), findsOneWidget);
  });
}
