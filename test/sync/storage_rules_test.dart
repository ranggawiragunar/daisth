import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routine image Storage rules are UID scoped and size/type bounded', () {
    final rules = File('storage.rules').readAsStringSync();

    expect(rules, contains('request.auth.uid == userId'));
    expect(rules, contains("fileName.matches('image\\\\.(jpg|png)')"));
    expect(rules, contains('request.resource.size <= 8 * 1024 * 1024'));
    expect(rules, contains("image/(jpeg|png)"));
    expect(rules, contains('allow read, write: if false'));
  });
}
