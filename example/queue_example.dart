import 'package:queue/queue.dart';

Future<void> main() async {
  final queue = Queue(delay: const Duration(milliseconds: 100));

  Future asyncMessage(String message) async {
    print(message);
  }

  unawaited(queue.add(() async {
    await asyncMessage("Message 1");
  }).then((result) => print("Message 1 complete")));

  await queue.add(() async {
    await asyncMessage("Message 2");
  });

  await Future.delayed(const Duration(milliseconds: 500));

  print('Message 2 complete');

  unawaited(queue.add(() async {
    await asyncMessage("Message 3");
    print("awaited message");
    throw Exception("Error");
  }).then((result) => print("Message 3 complete")));

  unawaited(queue
      .add(() async => asyncMessage("Message 4"))
      .then((result) => print("Message 4 complete")));
}

void unawaited(Future<void> future) {}
