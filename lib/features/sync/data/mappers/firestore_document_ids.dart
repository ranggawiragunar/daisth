abstract final class FirestoreDocumentIds {
  static String routineDefinition(String routineId) => _part(routineId);

  static String routineStepDefinition(String routineId, String stepId) =>
      '${_part(routineId)}__${_part(stepId)}';

  static String routineRecord(String dateKey, String routineId) =>
      '${dateKey}__${_part(routineId)}';

  static String routineStepRecord(
    String dateKey,
    String routineId,
    String stepId,
  ) => '${dateKey}__${_part(routineId)}__${_part(stepId)}';

  static String dailyReflection(String dateKey) => dateKey;

  static (String, String) splitPair(String id) {
    final separator = id.indexOf('__');
    if (separator <= 0 || separator + 2 >= id.length) {
      throw FormatException('Invalid composite sync identifier.');
    }
    return (
      Uri.decodeComponent(id.substring(0, separator)),
      Uri.decodeComponent(id.substring(separator + 2)),
    );
  }

  static (String, String, String) splitTriple(String id) {
    final first = id.indexOf('__');
    final second = id.indexOf('__', first + 2);
    if (first <= 0 || second <= first + 2 || second + 2 >= id.length) {
      throw FormatException('Invalid composite sync identifier.');
    }
    return (
      Uri.decodeComponent(id.substring(0, first)),
      Uri.decodeComponent(id.substring(first + 2, second)),
      Uri.decodeComponent(id.substring(second + 2)),
    );
  }

  static String _part(String value) =>
      Uri.encodeComponent(value).replaceAll('_', '%5F');
}
