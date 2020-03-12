Easily queue futures and await their values.

This library allows you to send a future to central queue. The queue will execute the futures in the order they are queued and once complete will return the result to the function.

The use case here was to rate limit calls to bluetooth devices. There were multiple bluetooth devices connected that may have different commands being sent from lots of areas in the app. The devices were tripping over themselves and not responding. A stream wasn't the appropriate tool as I needed to get the result back. Hence a library was born.

## Usage

A simple usage example:

```dart
import 'package:dart_queue/dart_queue.dart';

main() {
  final Queue queue = Queue(delay: Duration(milliseconds: 10));
  
  queue.add(()=>Future.delayed(Duration(milliseconds: 100)));
  queue.add(()=>Future.delayed(Duration(milliseconds: 10)));
  queue.add(()=>Future.delayed(Duration(milliseconds: 1)));
  
  //100, 10, 1 will reslove in that order.
  
}
```