/// Starts and health-checks the embedded Python backend.
///
/// MVP: [MockPythonRuntime] just waits a moment so the splash flow is real.
/// TODO(backend): implement `SeriousPythonRuntime`:
///   - generate a random per-launch token + pick a free port
///   - `SeriousPython.run(environmentVariables: {'JOURNEY_PORT': ..., 'JOURNEY_TOKEN': ...})`
///   - poll `GET /health` until 200 or [startTimeout]
///   - expose `baseUrl` + `token` for the LocalApi*Repository HTTP client
///   See .kiro/steering/api-contract.md ("Transport", "Lifecycle").
abstract interface class PythonRuntime {
  /// Starts Python (if needed) and resolves once `/health` responds.
  /// Throws [PythonStartException] on timeout/failure.
  Future<void> start();

  /// `GET /health`. Called on app resume because Android may kill the process.
  Future<bool> checkHealth();
}

class PythonStartException implements Exception {
  const PythonStartException(this.message);
  final String message;

  @override
  String toString() => 'PythonStartException: $message';
}

class MockPythonRuntime implements PythonRuntime {
  MockPythonRuntime({this.startDelay = const Duration(milliseconds: 1200)});

  // TODO(backend): remove. Simulates first-launch unpack + server boot time.
  final Duration startDelay;
  bool _started = false;

  @override
  Future<void> start() async {
    if (_started) return;
    await Future<void>.delayed(startDelay);
    _started = true;
  }

  @override
  Future<bool> checkHealth() async => _started; // TODO(backend): real GET /health.
}
