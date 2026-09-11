import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The evidence matrix is research tooling. It must not be a Flutter asset
/// and must not be referenced from `lib/`.
void main() {
  test('evidence matrix is not a Flutter asset or lib/ input', () {
    const matrixRef = 'tool/powertrain_evidence/matrix.json';
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains(matrixRef), isFalse);

    final assetPaths = <String>[];
    var inAssets = false;
    for (final line in pubspec.split('\n')) {
      if (line.startsWith('  assets:')) {
        inAssets = true;
        continue;
      }
      if (inAssets) {
        final stripped = line.trim();
        if (stripped.startsWith('- ')) {
          assetPaths.add(stripped.substring(2).trim());
        } else if (line.startsWith('  ') && !line.startsWith('    ')) {
          break;
        }
      }
    }
    bool coversMatrix(String asset) {
      final text = asset.replaceAll('\\', '/').trim();
      if (text == matrixRef) return true;
      if (text.isEmpty) return false;
      final directory = text.endsWith('/') ? text : '$text/';
      return matrixRef.startsWith(directory);
    }

    for (final asset in assetPaths) {
      expect(
        coversMatrix(asset),
        isFalse,
        reason: 'pubspec asset $asset would bundle $matrixRef',
      );
    }
    expect(coversMatrix('tool/powertrain_evidence/'), isTrue);
    expect(coversMatrix('tool/powertrain_evidence'), isTrue);
    expect(assetPaths, isNot(contains('assets/powertrain_battery/')));

    final libHits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('tool/powertrain_evidence') ||
          text.contains('powertrain_evidence/matrix.json')) {
        libHits.add(entity.path);
      }
    }
    expect(libHits, isEmpty);
  });
}
