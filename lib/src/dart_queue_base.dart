import 'dart:async';

class _QueuedFuture<T> {
  final Completer completer;
  final Future<T> Function() closure;

  _QueuedFuture(this.closure, this.completer);

  Future<void> execute() async {
    try {
      final result = await closure();
      completer.complete(result);
      //Make sure not to execute the next command until this future has completed
      await Future.microtask(() {});
    } catch (e) {
      completer.completeError(e);
    }
  }
}

/// Queue to execute Futures in order.
/// It awaits each future before executing the next one.
class Queue {
  final List<_QueuedFuture> _nextCycle = [];

  /// A delay to await between each future.
  final Duration delay;

  bool _isProcessing = false;
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  /// Cancels the queue.
  ///
  /// Subsquent calls to [add] will throw.
  void cancel() {
    _isCancelled = true;
  }

  /// Alias for [cancel].
  void dispose() {
    cancel();
  }

  Queue({this.delay});

  /// Adds the future-returning closure to the queue.
  ///
  /// It will be executed after futures returned
  /// by preceding closures have been awaited.
  ///
  /// Will throw an exception if the queue has been cancelled.
  Future<T> add<T>(Future<T> Function() closure) {
    if (isCancelled) throw Exception('Queue is cancelled');
    final completer = Completer<T>();
    _nextCycle.add(_QueuedFuture<T>(closure, completer));
    unawaited(_process());
    return completer.future;
  }

  Future<void> _process() async {
    if (!_isProcessing) {
      _isProcessing = true;
      final currentCycle = List.of(_nextCycle);
      _nextCycle.clear();
      for (final item in currentCycle) {
        await item.execute();
        if (delay != null) await Future.delayed(delay);
      }
      _isProcessing = false;
      if (!_isCancelled && _nextCycle.isNotEmpty) {
        await Future.microtask(() {}); // yield to prevent stack overflow
        unawaited(_process());
      }
    }
  }
}

// Don't throw analysis error on unawaited future.
void unawaited(Future<void> future) {}
