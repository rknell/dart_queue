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
    } catch (e) {
      completer.completeError(e);
    } finally {
      if (onComplete != null) onComplete();
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
  ///
  /// Can be edited mid processing
  int parallel;
  int _lastProcessId = 0;
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;
  final _remainingItemsController = StreamController<int>();

  Stream<int> get remainingItems =>
      _remainingItemsController.stream.asBroadcastStream();

  final List<Completer<void>> _completeListeners = [];

  /// Resolve when all items are complete
  ///
  /// Returns a future that will resolve when all items in the queue have
  /// finished processing
  Future get onComplete {
    final completer = Completer();
    _completeListeners.add(completer);
    return completer.future;
  }

  @Deprecated(
      "v3 - listen to the [remainingItems] stream to listen to queue status")
  Set<int> activeItems = {};

  /// Cancels the queue.
  ///
  /// Subsquent calls to [add] will throw.
  void cancel() {
    _isCancelled = true;
  }

  /// Alias for [cancel].
  void dispose() {
    _remainingItemsController.close();
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
    _remainingItemsController.sink.add(_nextCycle.length);
    unawaited(_process());
    return completer.future;
  }

  /// Handles the number of parallel tasks firing at any one time
  ///
  /// It does this by checking how many streams are running by querying active
  /// items, and then if it has less than the number of parallel operations fire off another stream.
  ///
  /// When each item completes it will only fire up one othe process
  ///
  Future<void> _process() async {
    if (activeItems.length < parallel) {
      _queueUpNext();
    }
  }

  void _queueUpNext() {
    if (_nextCycle.isNotEmpty &&
        !isCancelled &&
        activeItems.length <= parallel) {
      final processId = _lastProcessId;
      activeItems.add(processId);
      _lastProcessId++;
      final item = _nextCycle.first;
      _nextCycle.remove(item);
      item.onComplete = () async {
        activeItems.remove(processId);
        if (delay != null) {
          await Future.delayed(delay);
        }
        _remainingItemsController.sink.add(_nextCycle.length);
        _queueUpNext();
      };
      unawaited(item.execute());
    } else if (activeItems.isEmpty && _nextCycle.isEmpty) {
      //Complete
      for (final completer in _completeListeners) {
        if (completer.isCompleted != true) {
          completer.complete();
        }
      }
      _completeListeners.clear();
    }
  }
}

// Don't throw analysis error on unawaited future.
void unawaited(Future<void> future) {}
