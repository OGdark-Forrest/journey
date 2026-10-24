import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/happiness.dart';

/// Remembers which otter expression was shown on the previous app launch.
abstract interface class LaunchExpressionStore {
  Future<int?> readPrevious();
  Future<void> save(int mood);
}

/// On-device store. Survives app restarts (unlike the in-memory mock backend).
class SharedPrefsLaunchExpressionStore implements LaunchExpressionStore {
  static const _key = 'launch_otter_mood';

  @override
  Future<int?> readPrevious() async => (await SharedPreferences.getInstance()).getInt(_key);

  @override
  Future<void> save(int mood) async => (await SharedPreferences.getInstance()).setInt(_key, mood);
}

/// Picks a random expression (1-5) that differs from [previous] when
/// [previous] is a valid expression; otherwise any of the 5.
int pickLaunchMood(int? previous, math.Random rng) {
  final all = [for (var m = Happiness.min; m <= Happiness.max; m++) m];
  final valid = previous != null && previous >= Happiness.min && previous <= Happiness.max;
  final options = valid ? all.where((m) => m != previous).toList() : all;
  return options[rng.nextInt(options.length)];
}

/// The otter expression for this app launch. Chosen once in [init] and kept
/// for the life of the process.
class LaunchMood {
  LaunchMood(this._store, {math.Random? rng}) : _rng = rng ?? math.Random();

  final LaunchExpressionStore _store;
  final math.Random _rng;

  int? _mood;

  /// Valid after [init]; falls back to neutral if [init] never ran.
  int get mood => _mood ?? Happiness.neutral;

  /// Never throws: storage problems just mean "pick any expression".
  Future<void> init() async {
    if (_mood != null) return;
    int? previous;
    try {
      previous = await _store.readPrevious().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Launch otter: could not read previous expression: $e');
    }
    final mood = pickLaunchMood(previous, _rng);
    _mood = mood;
    unawaited(_store.save(mood).catchError((Object e) {
      debugPrint('Launch otter: could not save expression: $e');
    }));
  }
}
