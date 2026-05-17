void main() {
  const iterations = 1000000;

  // Benchmark ProfileSetupScreen RegExp
  final stopwatch1 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    RegExp(r'^[a-zA-Z0-9_]+$').hasMatch('mahin_27');
  }
  stopwatch1.stop();
  print('Baseline ProfileSetupScreen RegExp: ${stopwatch1.elapsedMicroseconds / iterations} µs/call');

  // Benchmark ProfileModel RegExp
  final stopwatch2 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    'Mahin Ahmed'.split(RegExp(r'[\s_]+'));
  }
  stopwatch2.stop();
  print('Baseline ProfileModel RegExp: ${stopwatch2.elapsedMicroseconds / iterations} µs/call');

  // Comparison with hoisted RegExp
  final regExp1 = RegExp(r'^[a-zA-Z0-9_]+$');
  final stopwatch3 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    regExp1.hasMatch('mahin_27');
  }
  stopwatch3.stop();
  print('Optimized ProfileSetupScreen RegExp: ${stopwatch3.elapsedMicroseconds / iterations} µs/call');

  final regExp2 = RegExp(r'[\s_]+');
  final stopwatch4 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    'Mahin Ahmed'.split(regExp2);
  }
  stopwatch4.stop();
  print('Optimized ProfileModel RegExp: ${stopwatch4.elapsedMicroseconds / iterations} µs/call');
}
