/// 랭킹 타입
enum RankingType {
  allTimeHighest,
  weeklyHighest,
  totalDestroys,
}

/// 랭킹 엔트리
class RankingEntry {
  final String playerId;
  final String nickname;
  final String? equippedTitle;
  final RankingType type;
  final int score;
  final DateTime updatedAt;

  const RankingEntry({
    required this.playerId,
    required this.nickname,
    this.equippedTitle,
    required this.type,
    required this.score,
    required this.updatedAt,
  });
}
