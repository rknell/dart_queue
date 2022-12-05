import 'package:queue/src/dart_queue_base.dart';
import 'package:test/test.dart';

void main() {
  group('Queue', () {
    late Queue queue;

    setUp(() {
      queue = Queue();
    });

    test('does it return', () async {
      final result = await queue
          .add(() => Future.delayed(const Duration(milliseconds: 100)));
      expect(result, null);
    });

    test('it should return a value', () async {
      final result = await queue.add(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return "result";
      });
      expect(result, "result");
    });

    test('it should return multiple values', () async {
      final result = await Future.wait([
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return "result 1";
        }),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return "result 2";
        }),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return "result 3";
        }),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 5));
          return "result 4";
        })
      ]);

      expect(result[0], "result 1");
      expect(result[1], "result 2");
      expect(result[2], "result 3");
      expect(result[3], "result 4");
    });

    test('it should queue', () async {
      final List<String?> results = [];

      await Future.wait([
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return "result 1";
        }).then((result) => results.add(result)),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return "result 2";
        }).then((result) => results.add(result)),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return "result 3";
        }).then((result) => results.add(result)),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 5));
          return "result 4";
        }).then((result) => results.add(result)),
        queue.add(() async {
          await Future.delayed(const Duration(milliseconds: 1));
          return "result 5";
        }).then((result) => results.add(result))
      ]);

      expect(results[0], "result 1");
      expect(results[1], "result 2");
      expect(results[2], "result 3");
      expect(results[3], "result 4");
      expect(results[4], "result 5");
    });

    test('it should run in parallel', () async {
      final List<String?> results = [];

      final queueParallel = Queue(parallel: 3);

      final List<int> remainingItemsResults = [];
      final remainingItemsStream = queueParallel.remainingItems
          .listen((items) => remainingItemsResults.add(items));

      await Future.wait([
        queueParallel.add(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return "result 1";
        }).then((result) => results.add(result)),
        queueParallel.add(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return "result 2";
        }).then((result) => results.add(result)),
        queueParallel.add(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return "result 3";
        }).then((result) => results.add(result)),
        queueParallel.add(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return "result 4";
        }).then((result) => results.add(result)),
        queueParallel.add(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return "result 5";
        }).then((result) => results.add(result))
      ]);

      await Future.delayed(const Duration(seconds: 1));

      unawaited(queueParallel.add(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return "result 1";
      }).then((result) => results.add(result)));
      unawaited(queueParallel.add(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return "result 2";
      }).then((result) => results.add(result)));
      unawaited(queueParallel.add(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return "result 3";
      }).then((result) => results.add(result)));
      unawaited(queueParallel.add(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return "result 4";
      }).then((result) => results.add(result)));
      unawaited(queueParallel.add(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return "result 5";
      }).then((result) => results.add(result)));

      await queueParallel.onComplete;

      expect(results[0], "result 3");
      expect(results[1], "result 4");
      expect(results[2], "result 2");
      expect(results[3], "result 5");
      expect(results[4], "result 1");

      expect(results[5], "result 3");
      expect(results[6], "result 4");
      expect(results[7], "result 2");
      expect(results[8], "result 5");
      expect(results[9], "result 1");

      await remainingItemsStream.cancel();
      expect(remainingItemsResults.isNotEmpty, true);
    });

    test('it should handle an error correctly (also testing oncomplete)',
        () async {
      int hitError = 0;
      final errorQueue = Queue(parallel: 10);
      for (var i = 0; i < 100; i++) {
        unawaited(errorQueue.add<Object?>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          throw Exception("test exception");
        }).catchError((err) {
          hitError++;
          expect(err.toString(), "Exception: test exception");
        }));
      }
      try {
        await errorQueue.add(() {
          Future.delayed(const Duration(milliseconds: 10));
          throw Exception("test exception");
        });
      } catch (e) {
        hitError++;
      }
      await errorQueue.onComplete;
      expect(errorQueue.activeItems.length, 0);
      expect(hitError, 101);
    });
  });

  test('should cancel', () async {
    final cancelQueue = Queue();
    final results = <String?>[];
    final errors = <Exception>[];

    unawaited(Future.wait([
      cancelQueue
          .add(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            return "result 1";
          })
          .then((result) => results.add(result))
          .catchError((err) => errors.add(err)),
      cancelQueue
          .add(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            return "result 2";
          })
          .then((result) => results.add(result))
          .catchError((err) => errors.add(err)),
      cancelQueue
          .add(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            return "result 3";
          })
          .then((result) => results.add(result))
          .catchError((err) => errors.add(err)),
      cancelQueue
          .add(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            return "result 4";
          })
          .then((result) => results.add(result))
          .catchError((err) => errors.add(err)),
      cancelQueue
          .add(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            return "result 5";
          })
          .then((result) => results.add(result))
          .catchError((err) => errors.add(err))
    ]));

    await Future.delayed(const Duration(milliseconds: 25));
    cancelQueue.cancel();
    await cancelQueue.onComplete;
    expect(results.length, 3);
    expect(errors.length, 2);
    expect(errors.first is QueueCancelledException, true);
  });

  test("timed out queue item still completes", () async {
    final queue = Queue(timeout: const Duration(milliseconds: 10));

    final resultOrder = [];

    unawaited(queue.onComplete.then((_) => resultOrder.add("timedout")));
    resultOrder.add(await queue.add(() async {
      await Future.delayed(const Duration(seconds: 1));
      return "test";
    }));

    expect(resultOrder.length, 2);
    expect(resultOrder.first, "timedout");
    expect(resultOrder[1], "test");
  });

  test("it handles null as expected", () async {
    final queue = Queue();

    final result = await queue.add(() async => null);
    expect(result, null);
  });
}
