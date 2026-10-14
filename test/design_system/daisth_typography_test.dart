import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/design_system/tokens/daisth_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Daisth typography uses the locally bundled brand font', () async {
    expect(DaisthTypography.bodyMedium.fontFamily, 'Plus Jakarta Sans');

    final font = await rootBundle.load(
      'assets/fonts/PlusJakartaSans-Variable.ttf',
    );
    expect(font.lengthInBytes, greaterThan(0));
  });
}
