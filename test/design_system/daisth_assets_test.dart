import 'package:daisth/core/design_system/assets/daisth_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('critical Daisth brand assets are registered', () async {
    for (final path in [
      DaisthAssets.mark,
      DaisthAssets.wordmark,
      DaisthAssets.lockup,
    ]) {
      await rootBundle.load(path);
    }
  });
}
