/// Supports the registration of Invocation matchers and exceptions. When actual
/// calls are made, the method checks if it should throw an exception. If not,
/// it is free to behave normally.
library mock_exceptions;

export 'src/mock_exceptions.dart' show whenCalling, maybeThrowException;
