import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/OFL-PlusJakartaSans.txt',
    );
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], license);
  });
  runApp(const DaisthApp());
}
