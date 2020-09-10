# Changelog

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