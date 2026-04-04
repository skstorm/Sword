/// 컬렉션 데이터
class CollectionData {
  final Map<int, int> collected;

  const CollectionData({this.collected = const {}});

  int get uniqueCount => collected.length;
  int get totalCollectible => 11;
  double get completionRate =>
      totalCollectible == 0 ? 0 : uniqueCount / totalCollectible;

  CollectionData copyWith({Map<int, int>? collected}) {
    return CollectionData(collected: collected ?? this.collected);
  }
}
