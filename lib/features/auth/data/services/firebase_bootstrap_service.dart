import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapService {
  bool isReady = false;

  Future<bool> initialize() async {
    if (isReady) return true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      isReady = Firebase.apps.isNotEmpty;
    } catch (_) {
      isReady = false;
    }
    return isReady;
  }
}
