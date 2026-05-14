import 'dart:async';

// Simulated service methods with 500ms delay each
Future<List<String>> fetchRoomsMock() async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ['room1', 'room2'];
}

Future<List<String>> getSubjectsMock() async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ['subject1', 'subject2'];
}

Future<int> runSequential() async {
  final stopwatch = Stopwatch()..start();

  // ignore: unused_local_variable
  final rooms = await fetchRoomsMock();
  // ignore: unused_local_variable
  final subjects = await getSubjectsMock();

  stopwatch.stop();
  final elapsed = stopwatch.elapsedMilliseconds;
  print('Sequential execution time: ${elapsed}ms');
  return elapsed;
}

Future<int> runParallel() async {
  final stopwatch = Stopwatch()..start();

  // Using List destructuring (Dart 3.0+)
  // ignore: unused_local_variable
  final [rooms, subjects] = await Future.wait([
    fetchRoomsMock(),
    getSubjectsMock(),
  ]);

  stopwatch.stop();
  final elapsed = stopwatch.elapsedMilliseconds;
  print('Parallel execution time: ${elapsed}ms');
  return elapsed;
}

void main() async {
  print('--- RoomSheet Load Optimization Benchmark ---');

  // Warm up
  await fetchRoomsMock();
  await getSubjectsMock();

  print('Running baseline (Sequential)...');
  final seqTime = await runSequential();

  print('Running optimized (Parallel)...');
  final parTime = await runParallel();

  final improvement = seqTime - parTime;
  final percent = ((seqTime - parTime) / seqTime * 100).toStringAsFixed(1);

  print('---------------------------------------------');
  print('Improvement: ${improvement}ms ($percent%)');
  print('---------------------------------------------');
}
