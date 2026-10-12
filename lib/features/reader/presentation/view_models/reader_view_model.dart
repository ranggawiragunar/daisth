import 'package:flutter/foundation.dart';

import '../../domain/models/reader_content.dart';

class ReaderViewModel extends ChangeNotifier {
  ReaderViewModel(this.content);

  static const supportedTextScales = [0.9, 1.0, 1.15, 1.3];

  final ReaderContent content;
  bool _transliterationVisible = true;
  bool _translationVisible = true;
  double _textScale = 1;

  bool get transliterationVisible => _transliterationVisible;
  bool get translationVisible => _translationVisible;
  double get textScale => _textScale;

  void setTransliterationVisible(bool visible) {
    if (_transliterationVisible == visible) return;
    _transliterationVisible = visible;
    notifyListeners();
  }

  void setTranslationVisible(bool visible) {
    if (_translationVisible == visible) return;
    _translationVisible = visible;
    notifyListeners();
  }

  bool setTextScale(double scale) {
    if (!supportedTextScales.contains(scale) || scale == _textScale) {
      return false;
    }
    _textScale = scale;
    notifyListeners();
    return true;
  }
}
