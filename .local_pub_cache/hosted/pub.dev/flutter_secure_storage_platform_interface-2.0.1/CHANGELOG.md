## 2.0.1
Remove dart:io to support WASM build of web.

## 2.0.0
- This plugin requires a minimum dart sdk of 3.3.0 or higher and a minimum flutter version of 3.19.0.
- Migrated to new analyzer and clean-up code.

## 1.1.2
Adds onCupertinoProtectedDataAvailabilityChanged and isCupertinoProtectedDataAvailable via MethodChannelFlutterSecureStorage to prevent breaking changes.

## 1.1.1
Reverts onCupertinoProtectedDataAvailabilityChanged and isCupertinoProtectedDataAvailable.

## 1.1.0
Adds onCupertinoProtectedDataAvailabilityChanged and isCupertinoProtectedDataAvailable.

## 1.0.2
- Update Dart SDK Constraint to support <4.0.0 instead of <3.0.0.

## 1.0.1
- Migrated from flutter_lints to lint and applied suggestions.
- Remove pubspec.lock according to https://dart.dev/guides/libraries/private-files#pubspeclock

## 1.0.0
- Initial release. Contains the interface and an implementation based on method channels.
- Changed effective_dart to flutter_lints