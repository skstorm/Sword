/// 검 데이터 모델 — swords.csv 한 행에 대응
class Sword {
  final int level;
  final String name;
  final String theme;
  final double? successRate; // 0.0~1.0, +0은 null
  final int enhanceCost; // +0은 0
  final int totalInvestment;
  final int? sellPrice; // +0은 null
  final double? returnRate; // +0은 null
  final int fragmentReward; // +0은 0
  final bool collectible;

  const Sword({
    required this.level,
    required this.name,
    required this.theme,
    this.successRate,
    this.enhanceCost = 0,
    this.totalInvestment = 0,
    this.sellPrice,
    this.returnRate,
    this.fragmentReward = 0,
    this.collectible = false,
  });

  @override
  String toString() => 'Sword(+$level $name)';
}

/// 검 데이터 테이블 — 레벨로 검 조회
class SwordDataTable {
  final List<Sword> _swords;

  SwordDataTable(this._swords);

  Sword? getSword(int level) {
    if (level < 0 || level >= _swords.length) return null;
    return _swords[level];
  }

  int get maxLevel => _swords.length - 1;

  List<Sword> get allSwords => List.unmodifiable(_swords);

  List<Sword> get collectibleSwords =>
      _swords.where((s) => s.collectible).toList();
}
