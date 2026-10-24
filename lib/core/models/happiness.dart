/// Happiness scale: 1-5. Each level maps to an otter expression.
abstract final class Happiness {
  static const min = 1;
  static const max = 5;
  static const neutral = 3;

  static const _labels = ['Rough', 'Low', 'Okay', 'Good', 'Great'];

  /// Display label, e.g. "Good".
  static String label(int value) => _labels[value.clamp(min, max) - min];

  /// Lowercase form used inside the journal sentence ("...and felt good.").
  static String phrase(int value) => label(value).toLowerCase();
}
