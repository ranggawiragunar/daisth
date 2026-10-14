import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android backup excludes the local SQLite database', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final legacyRules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();
    final extractionRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="true"'));
    expect(manifest, contains('@xml/backup_rules'));
    expect(manifest, contains('@xml/data_extraction_rules'));
    expect(legacyRules, contains('domain="database" path="."'));
    expect(extractionRules, contains('<cloud-backup>'));
    expect(extractionRules, contains('<device-transfer>'));
    expect(extractionRules, contains('domain="database" path="."'));
  });

  test('Android release manifest disallows cleartext traffic', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
