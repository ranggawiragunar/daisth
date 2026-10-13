import 'package:firebase_core/firebase_core.dart';

import '../../../../firebase_options.dart';

class FirebaseBootstrapService {
  bool isReady = false;

  Future<bool> initialize() async {
    if (isReady) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      isReady = Firebase.apps.isNotEmpty;
    } catch (_) {
      isReady = false;
    }
    return isReady;
  }
}
