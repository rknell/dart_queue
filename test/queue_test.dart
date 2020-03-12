import 'package:queue/queue.dart';
import 'package:test/test.dart';

void main() {
  group('Queue', () {
    Queue queue;

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
      final List<String> results = [];

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
        }).then((result) => results.add(result))
      ]);

      expect(results[0], "result 1");
      expect(results[1], "result 2");
      expect(results[2], "result 3");
      expect(results[3], "result 4");
    });
  });
}
