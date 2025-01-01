# queue

[![Build Status](https://github.com/rknell/dart_queue/workflows/Dart/badge.svg)](https://github.com/rknell/dart_queue/actions)

Easily queue futures and await their values.

This library allows you to send a future to central queue. The queue will execute the futures in the order they are queued and once the future is complete it will return its result.

My use case was to rate limit calls to bluetooth devices. There were multiple bluetooth devices connected that may have different commands being sent from lots of areas in the app. The devices were tripping over themselves and not responding. A stream wasn't the appropriate tool as I needed to get the result back. Hence a library was born.

Alternative use cases could be spidering a website, downloading a number of files, or rate limiting calls to an API.

## Usage

The most simple example:
```dart
import 'package:queue/queue.dart';

main() async {
  final queue = Queue();

  //Queue up a future and await its result
  final result = await queue.add(()=>Future.delayed(Duration(milliseconds: 10)));

  //Thats it!
}
```

A proof of concept:

```dart
import 'package:queue/queue.dart';

main() async {
  //Create the queue container
  final Queue queue = Queue(delay: Duration(milliseconds: 10));

  //Add items to the queue asyncroniously
  queue.add(()=>Future.delayed(Duration(milliseconds: 100)));
  queue.add(()=>Future.delayed(Duration(milliseconds: 10)));

  //Get a result from the future in line with await
  final result = await queue.add(() async {
    await Future.delayed(Duration(milliseconds: 1));
    return "Future Complete";
  });

  //100, 10, 1 will reslove in that order.
  result == "Future Complete"; //true
}
```

#### Parallel processing
This doesn't work in batches and will fire the next item as soon as as there is space in the queue
Use [Queue(delayed: ...)] to specify a delay before firing the next item

```dart
import 'package:queue/queue.dart';

main() async {
  final queue = Queue(parallel: 2);

  //Queue up a future and await its result
  final result1 = await queue.add(()=>Future.delayed(Duration(milliseconds: 10)));
  final result2 = await queue.add(()=>Future.delayed(Duration(milliseconds: 10)));

  //Thats it!
}
```

#### On complete
```dart
import 'package:queue/queue.dart';

main() async {
  final queue = Queue(parallel: 2);

  //Queue up a couple of futures
  queue.add(()=>Future.delayed(Duration(milliseconds: 10)));
  queue.add(()=>Future.delayed(Duration(milliseconds: 10)));


  // Will only resolve when all the queue items have resolved.
  await queue.onComplete;
}
```

#### Rate limiting
You can specify a delay before the next item is fired as per the following example:

```dart
import 'package:queue/queue.dart';

main() async {
  final queue = Queue(delay: Duration(milliseconds: 500)); // Set the delay here

  //Queue up a future and await its result
  final result1 = await queue.add(()=>Future.delayed(Duration(milliseconds: 10)));
  final result2 = await queue.add(()=>Future.delayed(Duration(milliseconds: 10)));

  //Thats it!
}
```

#### LIFO (Last In First Out)
You can configure the queue to process items in LIFO order (last in, first out) by setting the `lifo` parameter:

```dart
import 'package:queue/queue.dart';

main() async {
  // Create a LIFO queue
  final queue = Queue(lifo: true);

  // Add items to the queue
  queue.add(() => Future.delayed(Duration(milliseconds: 100)));  // Will be processed last
  queue.add(() => Future.delayed(Duration(milliseconds: 50)));   // Will be processed second
  queue.add(() => Future.delayed(Duration(milliseconds: 10)));   // Will be processed first
}
```

#### Adding items to the front of the queue
You can add items to the front of the queue to process them sooner using the `addToFront` parameter:

```dart
import 'package:queue/queue.dart';

main() async {
  final queue = Queue();

  // Add a regular item to the queue
  queue.add(() => Future.delayed(Duration(milliseconds: 100)));
  
  // Add an urgent item that should be processed next
  queue.add(
    () => Future.delayed(Duration(milliseconds: 50)),
    addToFront: true
  );
}
```

#### Cancel

If you need to stop a queue from processing call Queue.cancel();

This will cancel the remaining items in the queue by throwing a `QueueCancelledException`.
A cancelled queue is "dead" and should be recreated. If you try adding items to the queue after you
call cancel, it will throw a `QueueCancelledException`.

If you have no reason to listen to the results of the items, simply call dispose.

If you want to wait until all the items which are inflight complete, call Queue.onComplete first.

#### Disposing
If you need to dispose of the queue object (best practice in flutter any any time the queue object will close)
simply call queue.dispose();

This is necessary to close the `Queue.remainingItems` controller.

#### Reporting

If you want to query how many items are outstanding in the queue once, you can use the getter `remainingItemCount`.

```dart
import 'package:queue/queue.dart';
final queue = Queue();

final count = queue.remainingItemCount;
```

If you want to get notified when the remainingItemCount changes, listen to the Queue.remainingItems stream.

```dart
import 'package:queue/queue.dart';

final queue = Queue();
final remainingItemsStream = queue.remainingItems.listen((numberOfItems)=>print(numberOfItems));

//Queue up a couple of futures
queue.add(()=>Future.delayed(Duration(milliseconds: 10)));
queue.add(()=>Future.delayed(Duration(milliseconds: 10)));

// Will only resolve when all the queue items have resolved.
await queue.onComplete;
remainingItemsStream.close();
queue.dispose(); // Will clean up any resources in the queue if you are done with it.
```

## Contributing

Pull requests are welcome. There is a shell script `ci_checks.sh` that will run the checks to get
past CI and also format the code before committing. If that all passes your PR will likely be accepted.

Please write tests to cover your new feature.
