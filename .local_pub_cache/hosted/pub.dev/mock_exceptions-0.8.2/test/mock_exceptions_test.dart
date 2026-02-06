import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('mock', () {
    late MyFake f;

    setUp(() => f = MyFake());

    test('name', () {
      whenCalling(Invocation.getter(#name)).on(f).thenThrow(Exception());
      expect(() => f.name, throwsException);
      expect(() => f.description, returnsNormally);
    });

    test('type', () {
      whenCalling(Invocation.setter(#name, null)).on(f).thenThrow(Exception());
      expect(() => f.name, returnsNormally);

      whenCalling(Invocation.getter(#name)).on(f).thenThrow(Exception());
      expect(() => f.name, throwsException);
    });

    test('loose matching when omitting positional argument matcher', () {
      whenCalling(Invocation.method(#doSomething, null))
          .on(f)
          .thenThrow(Exception());
      expect(() => f.doSomething('fun'), throwsException);
    });

    test('positional arguments', () {
      expect(() => f.doSomething('no'), returnsNormally);

      whenCalling(Invocation.method(#doSomething, [equals('fun')]))
          .on(f)
          .thenThrow(Exception());
      expect(() => f.doSomething('fun'), throwsException);
      expect(() => f.doSomething('no fun'), returnsNormally);

      // Omitting equals when expecting equality.
      whenCalling(Invocation.method(#doSomething, ['no fun']))
          .on(f)
          .thenThrow(Exception());
      expect(() => f.doSomething('no fun'), throwsException);
    });

    test('named arguments', () {
      expect(f.add(i1: 2, i2: 3), 5);

      whenCalling(Invocation.method(
              #add, null, {#i1: greaterThan(0), #i2: anything}))
          .on(f)
          .thenThrow(Exception());

      expect(() => f.add(i1: 1, i2: 2), throwsException);
      expect(() => f.add(i1: -1, i2: 2), returnsNormally);
    });

    test('loose matching when omitting named argument matcher', () {
      whenCalling(Invocation.method(#add, null)).on(f).thenThrow(Exception());

      expect(() => f.add(i1: 1, i2: 2), throwsException);
    });

    test('type arguments', () {
      expect(f.makeList<int>(), []);

      whenCalling(Invocation.genericMethod(#makeList, [int], null))
          .on(f)
          .thenThrow(Exception());

      expect(() => f.makeList<int>(), throwsException);
    });

    test('loose matching when omitting type argument matcher', () {
      whenCalling(Invocation.genericMethod(#makeList, null, null))
          .on(f)
          .thenThrow(Exception());

      expect(() => f.makeList<int>(), throwsException);
    });
  });
}

class MyFake {
  get name {
    maybeThrowException(this, Invocation.getter(#name));
    return 'name';
  }

  get description {
    maybeThrowException(this, Invocation.getter(#description));
    return 'description';
  }

  String doSomething(String input) {
    maybeThrowException(this, Invocation.method(#doSomething, [input]));
    return 'it works';
  }

  int add({required int i1, required int i2}) {
    maybeThrowException(
        this, Invocation.method(#add, null, {#i1: i1, #i2: i2}));
    return i1 + i2;
  }

  List<T> makeList<T>() {
    maybeThrowException(this, Invocation.genericMethod(#makeList, [T], null));
    return List<T>.empty();
  }
}
