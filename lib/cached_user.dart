import 'package:hive_flutter/hive_flutter.dart';

part 'cached_user.g.dart';

@HiveType(typeId: 0)
class CachedUser {
  @HiveField(0)
  final String displayName;

  @HiveField(1)
  final DateTime timestamp;

  CachedUser({
    required this.displayName,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inHours > 24;
}
