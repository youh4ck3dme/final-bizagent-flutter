import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Branding Guard Test
/// Ensures that old launcher icon assets are never referenced in UI code.
/// This prevents regressions where someone accidentally uses icon.png
/// instead of the centralized BizLogoMark widget.
void main() {
  group('Branding Guard - No old icon references in /lib', () {
    test('assets/images/icon.png must NOT be referenced in lib/', () {
      final violations = _scanForPattern(
        'lib/',
        RegExp(r"assets/images/icon\.png"),
      );
      expect(
        violations,
        isEmpty,
        reason:
            'Found UI references to assets/images/icon.png. '
            'Use BizLogoMark() widget instead.\n'
            'Violations:\n${violations.join('\n')}',
      );
    });

    test('icon_fg.png must NOT be referenced in lib/', () {
      final violations = _scanForPattern(
        'lib/',
        RegExp(r'icon_fg\.png'),
      );
      expect(
        violations,
        isEmpty,
        reason:
            'Found UI references to icon_fg.png. '
            'This is a launcher-only asset.\n'
            'Violations:\n${violations.join('\n')}',
      );
    });

    test('BizLogoMark widget must exist', () {
      final file = File('lib/core/ui/biz_logo_mark.dart');
      expect(file.existsSync(), isTrue,
          reason: 'BizLogoMark widget file must exist');
    });

    test('Brand logo asset must exist', () {
      final file = File('assets/images/brand/logo_mark.png');
      expect(file.existsSync(), isTrue,
          reason: 'Brand logo_mark.png must exist in assets/images/brand/');
    });

    test('pubspec.yaml must include brand assets directory', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        pubspec.contains('assets/images/brand/'),
        isTrue,
        reason: 'pubspec.yaml must include assets/images/brand/ directory',
      );
    });
  });
}

/// Scans all .dart files in [directory] for [pattern] matches.
/// Returns list of "file:line: content" strings for violations.
List<String> _scanForPattern(String directory, RegExp pattern) {
  final violations = <String>[];
  final dir = Directory(directory);
  if (!dir.existsSync()) return violations;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          violations.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
  }
  return violations;
}
