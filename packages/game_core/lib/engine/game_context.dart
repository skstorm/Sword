import '../models/sword.dart';
import '../models/mastery.dart';
import '../util/random_provider.dart';
import '../util/time_provider.dart';

/// 커맨드 실행에 필요한 외부 의존성 묶음
class GameContext {
  final RandomProvider random;
  final TimeProvider time;
  final SwordDataTable swordTable;
  final MasteryLevelTable masteryTable;

  const GameContext({
    required this.random,
    required this.time,
    required this.swordTable,
    required this.masteryTable,
  });
}
