/// 칭호 데이터 (P3에서 상세 구현)
class TitleData {
  final Set<String> earned;
  final String? equipped;

  const TitleData({this.earned = const {}, this.equipped});

  TitleData copyWith({Set<String>? earned, String? equipped}) {
    return TitleData(
      earned: earned ?? this.earned,
      equipped: equipped ?? this.equipped,
    );
  }
}
