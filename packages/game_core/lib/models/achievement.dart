/// 업적 데이터 (P3에서 상세 구현)
class AchievementData {
  final Set<String> achieved;

  const AchievementData({this.achieved = const {}});

  AchievementData copyWith({Set<String>? achieved}) {
    return AchievementData(achieved: achieved ?? this.achieved);
  }
}
