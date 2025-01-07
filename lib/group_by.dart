/// Extension pour grouper une liste par une clé
extension ListGroupBy<T> on List<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final result = <K, List<T>>{};
    for (final item in this) {
      final key = keyFunction(item);
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }
}
