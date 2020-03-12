import 'dart:async';

class _QueuedFuture {
  final Completer completer;
  final Future Function() closure;

  _QueuedFuture(this.closure, this.completer);

  Future execute() async {
    try {
      final result = await closure().catchError(completer.completeError);
      completer.complete(result);
      //Make sure not to execute the next commpand until this future has completed
      await Future.microtask(() {});
    } catch (e) {
      completer.completeError(e);
    }
  }
}

class Queue {
  List<_QueuedFuture> nextCycle = [];
  List<_QueuedFuture> currentCycle;
  Duration delay;
  bool isProcessing = false;

  bool isCancelled = false;

  void cancel() {
    isCancelled = true;
  }

  void dispose() {
    cancel();
  }

  Queue({this.delay});

  Future add(Future Function() closure) {
    final completer = Completer();
    nextCycle.add(_QueuedFuture(closure, completer));
    unawaited(process());
    print("Queue Size ${nextCycle.length + currentCycle.length}");
    return completer.future;
  }

  Future<void> process() async {
    if (!isProcessing) {
      isProcessing = true;
      currentCycle = nextCycle;
      nextCycle = [];
      for (final _QueuedFuture item in currentCycle) {
        try {
          await item.execute();
          if (this.delay != null) await Future.delayed(delay);
        } catch (e) {
          print("error processing $e");
        }
      }
      isProcessing = false;
      if (isCancelled == false && nextCycle.isNotEmpty) {
        await Future.microtask(() {}); //Yield to prevent stack overflow
        unawaited(process());
      } else {
        print("queue complete...");
      }
    }
  }
}

// Don't throw analysis error on unawaited future.
void unawaited(Future<void> future) {}
