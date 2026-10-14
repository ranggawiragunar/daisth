import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest registers the local notification action receiver', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver',
      ),
    );
  });
}
