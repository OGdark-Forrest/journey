/// Spacing and radius scale. Keep layouts on this grid so screens feel consistent.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal padding for screen content.
  static const screen = 20.0;
}

abstract final class Radii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Depth of the "3D" bottom edge on chunky buttons/cards (Duolingo-style).
abstract final class Depth {
  static const button = 4.0;
  static const card = 3.0;
}
