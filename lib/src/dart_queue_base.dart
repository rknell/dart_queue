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

  int _parallelOverqueueComplete = 0;

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
    if (!_isProcessing) {
      _isProcessing = true;
      final currentCycle = List.of(_nextCycle);
      _nextCycle.clear();

      _parallelOverqueueComplete = 0;
      parallelCycleFuture = Completer();
      for (var i = 0; i < parallel; i++) {
        _queueUpNext(currentCycle);
      }
      await parallelCycleFuture.future;

      _isProcessing = false;
      if (!_isCancelled && _nextCycle.isNotEmpty) {
        await Future.microtask(() {}); // yield to prevent stack overflow
        unawaited(_process());
      }
    }
  }

  _queueUpNext(List<_QueuedFuture<dynamic>> currentCycle) {
    if (currentCycle.isNotEmpty) {
      final item = currentCycle.first;
      currentCycle.remove(item);
      item.onComplete = () => _queueUpNext(currentCycle);
      unawaited(item.execute());
    } else {
      _parallelOverqueueComplete++;
      if(_parallelOverqueueComplete == parallel){
        parallelCycleFuture.complete();
      }
    }
  }
}

// Don't throw analysis error on unawaited future.
void unawaited(Future<void> future) {}
