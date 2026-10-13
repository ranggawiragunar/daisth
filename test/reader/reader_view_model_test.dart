import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/reader/data/catalog/reader_content_catalog.dart';
import 'package:daisth/features/reader/presentation/view_models/reader_view_model.dart';

void main() {
  test('transliteration and translation are visible by default', () {
    final viewModel = ReaderViewModel(ReaderContentCatalog.bedtimeDua);
    addTearDown(viewModel.dispose);

    expect(viewModel.transliterationVisible, isTrue);
    expect(viewModel.translationVisible, isTrue);
    expect(viewModel.textScale, 1.0);
  });

  test('visibility settings can be changed independently', () {
    final viewModel = ReaderViewModel(ReaderContentCatalog.bedtimeDua);
    addTearDown(viewModel.dispose);

    viewModel.setTransliterationVisible(false);
    expect(viewModel.transliterationVisible, isFalse);
    expect(viewModel.translationVisible, isTrue);

    viewModel.setTranslationVisible(false);
    expect(viewModel.translationVisible, isFalse);
    viewModel.setTransliterationVisible(true);
    expect(viewModel.transliterationVisible, isTrue);
  });

  test('text size accepts only the supported discrete values', () {
    final viewModel = ReaderViewModel(ReaderContentCatalog.bedtimeDua);
    addTearDown(viewModel.dispose);

    expect(viewModel.setTextScale(1.15), isTrue);
    expect(viewModel.textScale, 1.15);
    expect(viewModel.setTextScale(2.5), isFalse);
    expect(viewModel.textScale, 1.15);
  });
}
