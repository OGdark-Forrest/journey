import 'package:material_ui/material_ui.dart';

import '../shared/theme/palette.dart';
import '../shared/theme/spacing.dart';

/// Extra colors the stock ColorScheme doesn't cover.
@immutable
class JourneyColors extends ThemeExtension<JourneyColors> {
  const JourneyColors({
    required this.primaryEdge,
    required this.cardEdge,
    required this.cardBorder,
    required this.mutedText,
    required this.flame,
    required this.flameTint,
    required this.selectedTint,
    required this.secondarySurface,
  });

  /// Bottom "3D" edge under primary buttons.
  final Color primaryEdge;

  /// Bottom "3D" edge under cards and secondary buttons.
  final Color cardEdge;
  final Color cardBorder;
  final Color mutedText;

  /// Streak flame color and its soft background.
  final Color flame;
  final Color flameTint;

  /// Background for selected options / edited chips.
  final Color selectedTint;
  final Color secondarySurface;

  static const light = JourneyColors(
    primaryEdge: Palette.mossDeep,
    cardEdge: Palette.sandDeep,
    cardBorder: Palette.sand,
    mutedText: Palette.mist,
    flame: Palette.clay,
    flameTint: Palette.clayLight,
    selectedTint: Palette.sageLight,
    secondarySurface: Palette.sand,
  );

  static const dark = JourneyColors(
    primaryEdge: Palette.nightSageDeep,
    cardEdge: Palette.nightEdge,
    cardBorder: Palette.nightSurfaceHigh,
    mutedText: Palette.nightMuted,
    flame: Palette.clay,
    flameTint: Color(0xFF3D2E24),
    selectedTint: Palette.nightSageTint,
    secondarySurface: Palette.nightSurfaceHigh,
  );

  @override
  JourneyColors copyWith() => this;

  @override
  JourneyColors lerp(JourneyColors? other, double t) {
    if (other == null) return this;
    return JourneyColors(
      primaryEdge: Color.lerp(primaryEdge, other.primaryEdge, t)!,
      cardEdge: Color.lerp(cardEdge, other.cardEdge, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      flame: Color.lerp(flame, other.flame, t)!,
      flameTint: Color.lerp(flameTint, other.flameTint, t)!,
      selectedTint: Color.lerp(selectedTint, other.selectedTint, t)!,
      secondarySurface: Color.lerp(secondarySurface, other.secondarySurface, t)!,
    );
  }
}

extension JourneyThemeX on BuildContext {
  JourneyColors get jc => Theme.of(this).extension<JourneyColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
}

/// Nunito is bundled as a variable font. Body text uses weight 630 (semibold);
/// headings go heavier for that friendly, chunky look.
const _bodyWeight = 630.0;
const _headingWeight = 800.0;

TextStyle _nunito(TextStyle? base, double wght) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: 'Nunito',
    // fontWeight keeps fallback fonts close; fontVariations drives the actual axis.
    fontWeight: wght >= 750 ? FontWeight.w800 : FontWeight.w600,
    fontVariations: [FontVariation('wght', wght)],
    letterSpacing: 0,
  );
}

TextTheme _textTheme(TextTheme base, Color text) {
  final t = base.apply(bodyColor: text, displayColor: text);
  return t.copyWith(
    displayLarge: _nunito(t.displayLarge, _headingWeight),
    displayMedium: _nunito(t.displayMedium, _headingWeight),
    displaySmall: _nunito(t.displaySmall, _headingWeight),
    headlineLarge: _nunito(t.headlineLarge, _headingWeight),
    headlineMedium: _nunito(t.headlineMedium, _headingWeight),
    headlineSmall: _nunito(t.headlineSmall, _headingWeight),
    titleLarge: _nunito(t.titleLarge, _headingWeight),
    titleMedium: _nunito(t.titleMedium, 750),
    titleSmall: _nunito(t.titleSmall, 750),
    bodyLarge: _nunito(t.bodyLarge, _bodyWeight).copyWith(fontSize: 17, height: 1.45),
    bodyMedium: _nunito(t.bodyMedium, _bodyWeight).copyWith(fontSize: 15, height: 1.4),
    bodySmall: _nunito(t.bodySmall, _bodyWeight),
    labelLarge: _nunito(t.labelLarge, _headingWeight).copyWith(fontSize: 16),
    labelMedium: _nunito(t.labelMedium, 750),
    labelSmall: _nunito(t.labelSmall, 750),
  );
}

ThemeData _build({
  required Brightness brightness,
  required ColorScheme scheme,
  required Color scaffold,
  required JourneyColors jc,
}) {
  final typography = Typography.material2021();
  final baseText = brightness == Brightness.light ? typography.black : typography.white;
  final textTheme = _textTheme(baseText, scheme.onSurface);

  final roundedLg = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
    fontFamily: 'Nunito',
    textTheme: textTheme,
    extensions: [jc],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      foregroundColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: roundedLg,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: roundedLg,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: jc.secondarySurface.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: jc.cardBorder, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: jc.cardBorder, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: jc.secondarySurface,
      thumbColor: scheme.primary,
      trackHeight: 8,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: jc.secondarySurface,
    ),
  );
}

abstract final class JourneyTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        scaffold: Palette.beige,
        jc: JourneyColors.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Palette.moss,
          onPrimary: Colors.white,
          primaryContainer: Palette.sageLight,
          onPrimaryContainer: Palette.mossDeep,
          secondary: Palette.bark,
          onSecondary: Colors.white,
          secondaryContainer: Palette.sand,
          onSecondaryContainer: Palette.barkDeep,
          tertiary: Palette.clay,
          onTertiary: Colors.white,
          error: Palette.error,
          onError: Colors.white,
          surface: Palette.cream,
          onSurface: Palette.cocoa,
          onSurfaceVariant: Palette.mist,
          outline: Palette.sandDeep,
          outlineVariant: Palette.sand,
        ),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scaffold: Palette.nightBg,
        jc: JourneyColors.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Palette.nightSage,
          onPrimary: Color(0xFF1E2A1C),
          primaryContainer: Palette.nightSageTint,
          onPrimaryContainer: Palette.nightSage,
          secondary: Color(0xFFC9A98C),
          onSecondary: Color(0xFF2A1F16),
          secondaryContainer: Palette.nightSurfaceHigh,
          onSecondaryContainer: Palette.nightText,
          tertiary: Palette.clay,
          onTertiary: Color(0xFF2A1F16),
          error: Color(0xFFE08A72),
          onError: Color(0xFF2A1F16),
          surface: Palette.nightSurface,
          onSurface: Palette.nightText,
          onSurfaceVariant: Palette.nightMuted,
          outline: Palette.nightSurfaceHigh,
          outlineVariant: Palette.nightSurfaceHigh,
        ),
      );
}
