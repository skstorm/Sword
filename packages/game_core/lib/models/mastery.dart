/// 장인 숙련도 레벨 데이터 — mastery_levels.csv 한 행에 대응
class MasteryLevel {
  final int level;
  final int requiredExp;
  final double costDiscount;
  final int fragmentBonus;
  final String visualId;
  final String rewardDescription;

  const MasteryLevel({
    required this.level,
    required this.requiredExp,
    required this.costDiscount,
    required this.fragmentBonus,
    required this.visualId,
    required this.rewardDescription,
  });

  @override
  String toString() => 'MasteryLevel(Lv.$level)';
}

/// 장인 숙련도 레벨 테이블
class MasteryLevelTable {
  final List<MasteryLevel> _levels;

  MasteryLevelTable(this._levels);

  MasteryLevel getLevel(int level) {
    return _levels.firstWhere(
      (l) => l.level == level,
      orElse: () => _levels.first,
    );
  }

  /// 누적 경험치(강화 횟수)에 해당하는 레벨 반환
  int getLevelForExp(int totalAttempts) {
    int result = 1;
    for (final level in _levels) {
      if (totalAttempts >= level.requiredExp) {
        result = level.level;
      } else {
        break;
      }
    }
    return result;
  }

  String? getReward(int level) {
    final l = _levels.where((lv) => lv.level == level);
    return l.isEmpty ? null : l.first.rewardDescription;
  }

  List<MasteryLevel> get allLevels => List.unmodifiable(_levels);
}
