import 'package:flutter/painting.dart';

/// Earthy, low-vibrancy palette: sage greens, bark browns, beige.
///
/// Primary text/button colors were picked to keep >= 4.5:1 contrast against
/// their backgrounds. Re-check contrast if you tweak these.
abstract final class Palette {
  // ---- Light ----
  static const beige = Color(0xFFF5EFE6); // scaffold background
  static const cream = Color(0xFFFFFBF5); // card surface
  static const sand = Color(0xFFEADFCC); // secondary surface / borders
  static const sandDeep = Color(0xFFD9CBB4); // card "3D" edge, outlines

  static const sageLight = Color(0xFFDCE7D6); // selected tint, containers
  static const sage = Color(0xFFA9C4A3); // decorative green
  static const moss = Color(0xFF5E7F5A); // primary (buttons, accents)
  static const mossDeep = Color(0xFF465F43); // primary button edge

  static const bark = Color(0xFF7A5C43); // secondary brown
  static const barkDeep = Color(0xFF5A4231);
  static const cocoa = Color(0xFF3E3229); // body text
  static const mist = Color(0xFF7D7268); // muted text

  static const clay = Color(0xFFC98B5E); // streak flame (muted terracotta)
  static const clayDeep = Color(0xFFA36D45);
  static const clayLight = Color(0xFFF3E1D2);

  static const error = Color(0xFFB5543C);

  // ---- Dark ----
  static const nightBg = Color(0xFF1E1B17);
  static const nightSurface = Color(0xFF2A2621);
  static const nightSurfaceHigh = Color(0xFF353029);
  static const nightEdge = Color(0xFF151310);
  static const nightSage = Color(0xFFA3C19F);
  static const nightSageDeep = Color(0xFF6E8C6A);
  static const nightSageTint = Color(0xFF34402F);
  static const nightText = Color(0xFFF1E9DD);
  static const nightMuted = Color(0xFFB5AA9C);

  // ---- Otter mascot ----
  static const otterFur = Color(0xFF8A6446);
  static const otterFurDark = Color(0xFF6B4C34);
  static const otterMuzzle = Color(0xFFE9D6BF);
  static const otterNose = Color(0xFF3A2A20);
  static const otterBlush = Color(0xFFE3A58A);

  /// Confetti colors stay in-palette so celebrations feel calm, not loud.
  static const confetti = [moss, sage, clay, bark, sand, sageLight];
}
