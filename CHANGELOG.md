# Changelog

## 3.1.0+2

- Ensures stack trace isn't swallowed when an error occurs (thanks @Bungeefan)

## 3.1.0+1

- Fix a bug which would break if the queue stream had been disposed and an item completes.

## 3.1.0

- BREAKING: Stopping forced nullability of responses. Was hiding a bunch of null errors that would crash an app on launch

## 3.0.0

- Initial null safe release

## 2.0.7+2

- Fixing bug where trying to cancel items stream and it doesn't exist

## 2.0.7+1

- Fixing a bug where the timeout would not return later if the queue promise timed out.

## 2.0.7

- Potentially breaking: Updated remainingItems stream to include all items that are both waiting to start and in progress (previously it was just waiting to start)
- Updating remainingItems stream when adding an item as well as upon completion
- Adding a timeout. This will not cancel the future but will fire off new items in the queue if the future reaches its timeout.
- Remaining items stream is now lazily created to prevent memory leaks if you aren't using it.

## 2.0.6

- Adding onComplete getter

## 2.0.5

- Fixing incorrect reporting of items in queue

## 2.0.4

- Fixing cancelled not being respected when queueing up new items
- Adding remainingItems stream
- Deprecating public access to activeItems set

## 2.0.3

- Fixing delay not being respected

## 2.0.2

- Parallel performance improvements

## 2.0.1

- Adding parallel option

## 2.0.0

- Futures returned by `add` are typed.
- **Breaking**: Some fields related to the internal implementation are private.
- **Breaking**: `delay` cannot be modified after instantiation.
- **Breaking**: An exception will be thrown if `add` is called after the queue has been cancelled.

## 1.0.1+2

- Improving the readme

## 1.0.1+1

- Improving the package description

## 1.0.1

- Removing some console output

## 1.0.0

- Initial version