void main() {
  const int iterations = 1000000;
  const String testString = 'john_doe';

  print('Running benchmark with $iterations iterations...\n');

  // Benchmark Inline RegExp for username validation
  final stopwatch1 = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(testString);
  }
  stopwatch1.stop();
  print(
    'Inline RegExp (Validation): ${stopwatch1.elapsedMicroseconds / iterations} µs per call',
  );

  // Benchmark Static RegExp for username validation
  final staticRegExp1 = RegExp(r'^[a-zA-Z0-9_]+$');
  final stopwatch2 = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    staticRegExp1.hasMatch(testString);
  }
  stopwatch2.stop();
  print(
    'Static RegExp (Validation): ${stopwatch2.elapsedMicroseconds / iterations} µs per call',
  );

  print('');

  // Benchmark Inline RegExp for splitting
  final stopwatch3 = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    testString.split(RegExp(r'[\s_]+'));
  }
  stopwatch3.stop();
  print(
    'Inline RegExp (Split): ${stopwatch3.elapsedMicroseconds / iterations} µs per call',
  );

  // Benchmark Static RegExp for splitting
  final staticRegExp2 = RegExp(r'[\s_]+');
  final stopwatch4 = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    testString.split(staticRegExp2);
  }
  stopwatch4.stop();
  print(
    'Static RegExp (Split): ${stopwatch4.elapsedMicroseconds / iterations} µs per call',
  );
}
