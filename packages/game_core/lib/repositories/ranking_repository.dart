import '../models/ranking.dart';

/// 랭킹 저장소 인터페이스 (P3에서 구현)
abstract class RankingRepository {
  Future<List<RankingEntry>> getTopRanking(RankingType type, {int limit = 100});
  Future<void> submitScore(RankingEntry entry);
  Future<RankingEntry?> getMyRanking(RankingType type, String playerId);
}
