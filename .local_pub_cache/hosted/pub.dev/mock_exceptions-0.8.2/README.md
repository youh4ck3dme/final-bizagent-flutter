# mock_exceptions

[![pub package](https://img.shields.io/pub/v/mock_exceptions.svg)](https://pub.dartlang.org/packages/mock_exceptions)
[![Dart](https://github.com/atn832/mock_exceptions/actions/workflows/dart.yml/badge.svg)](https://github.com/atn832/mock_exceptions/actions/workflows/dart.yml)

Provides a mechanism to throw exceptions on certain calls. This is useful when working with a Fake and we still want to occasionally make it throw exceptions. At a glance:

```dart
final f = MyFake();
whenCalling(Invocation.method(#doSomething, null))
    .on(f)
    .thenThrow(Exception());
expect(() => f.doSomething(), throwsException);
```

## Features

- supports mocking exceptions for methods, getters, setters.
- supports matching on positional parameters, named parameters and type parameters (generics).
- supports regular [matchers](https://pub.dev/documentation/matcher/latest/matcher/matcher-library.html).
- supports omitting parameters when matching with `anything`.

For exhaustive usage, see our [unit tests](https://github.com/atn832/mock_exceptions/blob/main/test/mock_exceptions_test.dart).

## Differences with Mockito

Mockito lets you mock and stub methods. That means it lets you return predefined responses and throw exceptions, but not act as closely to the real thing as a Fake. Since mock_exceptions is supposed to be used on Fakes, its API unambiguously lets you mock only exceptions.

## Usage

1. In your Fake method/getter/setter implementation, add `maybeThrowException` at the beginning.
1. In your unit test, set up an expectation, then verify your expectations as usual.

### Before

Your Fake method might look like this. It does some real work.

```dart
class MyFake {
  String doSomething(String input) {
    return 'it works';
  }
}
```

Your unit test might even check that it works.

```dart
final fake = MyFake();
expect(fake.doSomething('yes'), 'it works');
```

### After

Your Fake method checks for possible exceptions before doing the work.

```dart
class MyFake {
  String doSomething(String input) {
    maybeThrowException(this, Invocation.method(#doSomething, [input]));
    return 'it works';
  }
}
```

You can now forcefully throw exceptions and test for them.

```dart
final fake = MyFake();
whenCalling(Invocation.method(#doSomething, ['fun']))
    .on(fake)
    .thenThrow(Exception());
expect(() => fake.doSomething('fun'), throwsException);
```

## Design considerations

- `whenCalling(Invocation.method(#doSomething, [equals('fun')])).on(fake).thenThrow(Exception());` is too verbose. Why not reimplement Mockito's API so that I can write `when(fake.doSomething('fun')).thenThrow(Exception())`?
  - Implementing Mockito's API requires relying on the `noSuchMethod` trick to detect the Invocation. As of writing, Mockito's [mock.dart](https://github.com/dart-lang/mockito/blob/master/lib/src/mock.dart) takes 1200 lines of code while our [mock_exceptions.dart](https://github.com/atn832/mock_exceptions/blob/main/lib/src/mock_exceptions.dart) takes around 80. Even if we pare Mockito's down to the minimum (excluding verifications, captures), it'd still take around 500 lines of code.
  - It also forces the Fakes to extend a pre-defined class, `Mock` in Mockito's case. In some projects such as Fake Cloud Firestore ([example](https://github.com/atn832/fake_cloud_firestore/blob/ac1d536f43048a152f78e643315f3f9326722d3e/lib/src/mock_collection_reference.dart#L16)), we actually need to extend another class.
- The Mockito API has its own downsides and gotchas. See how one should use named arguments [here](https://pub.dev/packages/mockito#named-arguments). Also you need to use its wrappers around the regular Matchers, such as `any` instead of `anything`, and `argThat(matcher)`.
