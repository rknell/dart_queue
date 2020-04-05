# queue
[![Build Status](https://travis-ci.org/rknell/dart_queue.svg?branch=master)](https://travis-ci.org/rknell/dart_queue)

Easily queue futures and await their values.

This library allows you to send a future to central queue. The queue will execute the futures in the order they are queued and once the future is complete it will return its result.

My use case was to rate limit calls to bluetooth devices. There were multiple bluetooth devices connected that may have different commands being sent from lots of areas in the app. The devices were tripping over themselves and not responding. A stream wasn't the appropriate tool as I needed to get the result back. Hence a library was born.

Alternative use cases could be spidering a website, downloading a number of files, or rate limiting calls to an API.

## Usage

A simple usage example:

```dart
import 'package:dart_queue/dart_queue.dart';

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