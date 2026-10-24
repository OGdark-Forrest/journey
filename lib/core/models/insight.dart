/// Which LLM endpoint produced an [Insight].
enum InsightKind {
  /// `POST /reflection`: a look back at one day.
  reflection,

  /// `POST /recommendations`: a plan for one day ahead.
  recommendations,
}

/// One line inside an [InsightSection].
class InsightLine {
  const InsightLine(this.text, {this.bullet = false, this.subheading = false});

  /// Text with list markers / heading hashes removed. May still contain
  /// `**bold**` spans.
  final String text;

  /// Came from a `-`, `*`, `•` or `1.` list item.
  final bool bullet;

  /// A `###` heading or a line that is entirely bold (e.g. `**Morning**`).
  final bool subheading;
}

/// A `## Heading` block of the model's answer.
class InsightSection {
  const InsightSection({required this.heading, required this.lines});

  /// Empty for text that came before the first `##` heading.
  final String heading;
  final List<InsightLine> lines;

  /// Plain body text, list items included, without markdown.
  String get plainText => lines.map((l) => Insight.stripBold(l.text)).join('\n');

  bool matches(String name) => heading.toLowerCase().trim() == name.toLowerCase();
}

/// Text returned by `POST /reflection` or `POST /recommendations`, split into
/// the sections the Python prompt asks for (see lib/core/python/serverRec.py):
///
/// - reflection: "Goal alignment", "Overall feeling", "What could have been better"
/// - recommendations: "Day plan", "Goal focus"
///
/// When the user logged nothing for the day, the reflection endpoint returns
/// one plain sentence with no headings; [isEmpty] is true then.
class Insight {
  Insight({
    required this.kind,
    required this.day,
    required this.text,
    required this.entryCount,
    DateTime? generatedAt,
  })  : sections = parseSections(text),
        generatedAt = generatedAt ?? DateTime.now();

  // Headings the Python prompts ask for. Keep in sync with serverRec.py.
  static const goalAlignment = 'Goal alignment';
  static const overallFeeling = 'Overall feeling';
  static const couldBeBetter = 'What could have been better';
  static const dayPlan = 'Day plan';
  static const goalFocus = 'Goal focus';

  final InsightKind kind;

  /// The day reflected on, or the day planned.
  final DateTime day;

  /// Raw model output (markdown).
  final String text;

  /// Logs sent with the request that fall on [day] (reflection) or in the
  /// recent window (recommendations). Shown as "Based on n entries".
  final int entryCount;
  final DateTime generatedAt;
  final List<InsightSection> sections;

  /// Sections with a heading. Text before the first heading is in [intro].
  List<InsightSection> get headedSections => [for (final s in sections) if (s.heading.isNotEmpty) s];

  InsightSection? get intro {
    final first = sections.isEmpty ? null : sections.first;
    return first != null && first.heading.isEmpty && first.lines.isNotEmpty ? first : null;
  }

  /// No `##` headings: the service had nothing to say (e.g. no logs that day).
  bool get isEmpty => headedSections.isEmpty;

  InsightSection? section(String heading) {
    for (final s in sections) {
      if (s.matches(heading)) return s;
    }
    return null;
  }

  /// Reflection only: the 1-10 happiness score from "Overall feeling".
  int? get happinessScore {
    final body = section(overallFeeling)?.plainText;
    if (body == null) return null;
    final match = RegExp(r'\b(10|[1-9])\s*(?:/|out of)\s*10\b').firstMatch(body);
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// Recommendations only: push / balanced / rest, from "Goal focus".
  DayType? get dayType {
    final body = section(goalFocus)?.plainText.toLowerCase();
    if (body == null) return null;
    // Earliest mention wins ("a balanced day rather than a push day").
    DayType? best;
    var bestAt = -1;
    for (final t in DayType.values) {
      final at = body.indexOf(RegExp('${t.name} day'));
      if (at >= 0 && (bestAt < 0 || at < bestAt)) {
        best = t;
        bestAt = at;
      }
    }
    return best;
  }

  /// Recommendations only: "Day plan" items grouped by part of day. Items the
  /// model didn't put under a part are left out; use [section] for the raw text.
  Map<DayPart, List<String>> get plan {
    final lines = section(dayPlan)?.lines ?? const [];
    final out = {for (final p in DayPart.values) p: <String>[]};
    DayPart? current;
    for (final line in lines) {
      final text = stripBold(line.text);
      final (part, rest) = DayPart.splitLabel(text);
      if (part != null) {
        current = part;
        // "Morning: walk, then breakfast" carries items on the same line.
        if (rest.isNotEmpty) out[part]!.add(rest);
        continue;
      }
      if (current != null && text.isNotEmpty) out[current]!.add(text);
    }
    return out;
  }

  /// Splits markdown into `##` sections. Top-level `#` titles are dropped;
  /// `###` headings become [InsightLine.subheading] lines.
  static List<InsightSection> parseSections(String markdown) {
    final sections = <InsightSection>[];
    var heading = '';
    var lines = <InsightLine>[];

    void flush() {
      if (heading.isNotEmpty || lines.isNotEmpty) {
        sections.add(InsightSection(heading: heading, lines: lines));
      }
    }

    for (final raw in markdown.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final h2 = RegExp(r'^##\s+(.*)$').firstMatch(line);
      if (h2 != null) {
        flush();
        heading = stripBold(h2.group(1)!).trim();
        lines = [];
        continue;
      }
      if (RegExp(r'^#\s').hasMatch(line)) continue;
      final h3 = RegExp(r'^#{3,}\s+(.*)$').firstMatch(line);
      if (h3 != null) {
        lines.add(InsightLine(h3.group(1)!.trim(), subheading: true));
        continue;
      }
      final item = RegExp(r'^(?:[-*•]|\d+[.)])\s+(.*)$').firstMatch(line);
      if (item != null) {
        lines.add(InsightLine(item.group(1)!.trim(), bullet: true));
        continue;
      }
      final allBold = RegExp(r'^\*\*([^*]+)\*\*:?$').firstMatch(line);
      if (allBold != null) {
        lines.add(InsightLine(allBold.group(1)!.trim(), subheading: true));
        continue;
      }
      lines.add(InsightLine(line));
    }
    flush();
    return sections;
  }

  static String stripBold(String s) => s.replaceAll('**', '').replaceAll('__', '');
}

/// The kind of day "Goal focus" recommends.
enum DayType {
  push,
  balanced,
  rest;

  String get label => switch (this) {
        DayType.push => 'Push day',
        DayType.balanced => 'Balanced day',
        DayType.rest => 'Rest day',
      };
}

/// Parts of the day used by "Day plan". Matches the Python time blocks
/// (night is folded into evening for planning).
enum DayPart {
  morning,
  afternoon,
  evening;

  String get label => name[0].toUpperCase() + name.substring(1);

  /// "Morning: walk" -> (morning, "walk"). "Morning (8-11am)" -> (morning, "").
  /// Anything else, including "Morning walk", -> (null, text).
  static (DayPart?, String) splitLabel(String text) {
    final m = RegExp(
      r'^(morning|afternoon|evening|night)\s*(?:\([^)]*\))?\s*(?:[:\-–—]\s*(.*))?$',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return (null, text);
    final word = m.group(1)!.toLowerCase();
    final part = word == 'night' ? DayPart.evening : DayPart.values.byName(word);
    return (part, (m.group(2) ?? '').trim());
  }
}
