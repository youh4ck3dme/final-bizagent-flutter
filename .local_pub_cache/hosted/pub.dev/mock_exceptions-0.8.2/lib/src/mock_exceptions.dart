import 'package:matcher/matcher.dart';

Map<Object, Map<Invocation, Exception>> expectations = {};

void _register(Object o, Invocation i, Exception e) {
  expectations.putIfAbsent(o, () => {});
  expectations[o]![i] = e;
}

/// To be used within Fakes. The method calls this to throw an exception if a
/// matching invocation has been registered. If not, the method can behave
/// normally.
void maybeThrowException(Object o, Invocation i) {
  // check the registry. Throw an error, or nothing.
  if (!expectations.containsKey(o)) {
    return;
  }
  for (final expectation in (expectations[o] ?? {}).entries) {
    if (_matches(expectation.key, i)) {
      throw expectation.value;
    }
  }
}

/// Similar to String.padRight, but with lists.
List<T> _padRight<T>(List<T> l1, int width, T value) {
  if (width <= l1.length) {
    return l1;
  }
  return [...l1, ...List.filled(width - l1.length, value)];
}

bool _matches(
    Invocation invocationWithMatchers, Invocation concreteInvocation) {
  // Fill missing positional arguments with `anything` matchers.
  final loosePositionalArgumentMatchers = _padRight(
      invocationWithMatchers.positionalArguments,
      concreteInvocation.positionalArguments.length,
      anything);
  // Fill missing named arguments with `anything` matchers.
  final looseNamedArgumentMatchers = {
    // Start with a full map of `anything` matchers.
    ...Map.fromIterable(concreteInvocation.namedArguments.keys,
        value: (element) => anything),
    // Override with specific matchers.
    ...invocationWithMatchers.namedArguments,
  };
  final looseTypeArgumentMatchers = _padRight(
      invocationWithMatchers.typeArguments,
      concreteInvocation.typeArguments.length,
      anything);
  return invocationWithMatchers.isMethod == concreteInvocation.isMethod &&
      invocationWithMatchers.isGetter == concreteInvocation.isGetter &&
      invocationWithMatchers.isSetter == concreteInvocation.isSetter &&
      invocationWithMatchers.memberName == concreteInvocation.memberName &&
      equals(loosePositionalArgumentMatchers)
          .matches(concreteInvocation.positionalArguments, {}) &&
      equals(looseNamedArgumentMatchers)
          .matches(concreteInvocation.namedArguments, {}) &&
      equals(looseTypeArgumentMatchers)
          .matches(concreteInvocation.typeArguments, {});
}

/// Named differently from Mockito's `when` to prevent conflicts.
PostWhenCalling whenCalling(Invocation i) {
  return PostWhenCalling(i);
}

class PostWhenCalling<T> {
  PostWhenCalling(this.i);

  final Invocation i;

  PostOn<T> on(Object o) {
    return PostOn<T>(o, i);
  }
}

class PostOn<T> {
  PostOn(this.o, this.i);

  final Object o;
  final Invocation i;

  thenThrow(Exception e) {
    // o i e, literally Oh yeah.
    _register(o, i, e);
  }
}
