import 'package:flutter/foundation.dart';

import '../../core/models/assessment.dart';
import '../../core/repositories/repositories.dart';

/// Drives the one-question-per-page onboarding flow.
class AssessmentController extends ChangeNotifier {
  AssessmentController(this._repo);

  final AssessmentRepository _repo;

  List<AssessmentQuestion> _questions = const [];
  List<AssessmentQuestion> get questions => _questions;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _submitting = false;
  bool get submitting => _submitting;

  int _index = 0;
  int get index => _index;

  /// questionId -> answer. Multi-select answers keep a set until submit.
  final Map<String, AssessmentAnswer> _answers = {};
  final Map<String, Set<String>> _multi = {};

  AssessmentQuestion? get current => _questions.isEmpty ? null : _questions[_index];
  bool get isLast => _index == _questions.length - 1;
  double get progress => _questions.isEmpty ? 0 : (_index + 1) / _questions.length;

  AssessmentAnswer? answerFor(String questionId) => _answers[questionId];
  Set<String> multiFor(String questionId) => _multi[questionId] ?? const {};

  bool get canContinue {
    final q = current;
    if (q == null) return false;
    if (q.type == QuestionType.multi) return multiFor(q.id).isNotEmpty;
    final a = _answers[q.id];
    return a != null && a.value.trim().isNotEmpty;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _questions = await _repo.fetchQuestions();
    } catch (e) {
      _error = 'Couldn\'t load the questions.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void answer(String value, {bool custom = false}) {
    final q = current!;
    _answers[q.id] = AssessmentAnswer(questionId: q.id, value: value, custom: custom);
    notifyListeners();
  }

  void toggleMulti(String value) {
    final q = current!;
    final set = {...multiFor(q.id)};
    set.contains(value) ? set.remove(value) : set.add(value);
    _multi[q.id] = set;
    notifyListeners();
  }

  void next() {
    if (!isLast) {
      _index++;
      notifyListeners();
    }
  }

  bool back() {
    if (_index == 0) return false;
    _index--;
    notifyListeners();
    return true;
  }

  Future<bool> submit() async {
    _submitting = true;
    notifyListeners();
    try {
      final answers = [
        ..._answers.values,
        for (final e in _multi.entries)
          if (e.value.isNotEmpty) AssessmentAnswer(questionId: e.key, value: e.value.join(', ')),
      ];
      await _repo.submit(answers);
      return true;
    } catch (e) {
      _error = 'Couldn\'t save your answers. Please try again.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
