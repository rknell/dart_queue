import 'dart:async';

class _QueuedFuture<T> {
  final Completer completer;
  final Future<T> Function() closure;

  _QueuedFuture(this.closure, this.completer, {this.onComplete});

  Function onComplete;

  Future<void> execute() async {
    try {
      final result = await closure();
      completer.complete(result);
      //Make sure not to execute the next command until this future has completed
      await Future.microtask(() {});
      if (onComplete != null) onComplete();
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

  /// The number of items to process at one time
  final int parallel;

  int _lastProcessId = 0;

  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  Set<int> activeItems = {};

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

  Queue({this.delay, this.parallel = 1});

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

  Completer parallelCycleFuture;

  Future<void> _process() async {
    if(activeItems.length < parallel){
      _queueUpNext();
    }
  }

  void _queueUpNext() {
    if (_nextCycle.isNotEmpty) {
      var processId = _lastProcessId;
      activeItems.add(processId);
      _lastProcessId++;
      final item = _nextCycle.first;
      _nextCycle.remove(item);
      item.onComplete = () async {
        if(delay != null){
          await Future.delayed(delay);
        }
        _queueUpNext();
        activeItems.remove(processId);
      };
      unawaited(item.execute());
    }
  }
}

// Don't throw analysis error on unawaited future.
void unawaited(Future<void> future) {}
