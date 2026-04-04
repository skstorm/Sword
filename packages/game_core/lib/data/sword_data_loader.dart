import '../models/sword.dart';

/// swords.csv 파서 — CSV 문자열을 받아서 Sword 리스트 반환
/// game_core는 Flutter import 금지이므로 파일 읽기는 외부에서 처리
class SwordDataLoader {
  List<Sword> parse(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    // 첫 행은 헤더 — 스킵
    final swords = <Sword>[];
    for (var i = 1; i < lines.length; i++) {
      try {
        final sword = _parseLine(lines[i]);
        if (sword != null) swords.add(sword);
      } catch (_) {
        // 파싱 실패 시 해당 행 스킵
      }
    }
    return swords;
  }

  Sword? _parseLine(String line) {
    final cols = line.split(',');
    if (cols.length < 10) return null;

    final levelStr = cols[0].trim().replaceAll('+', '');
    final level = int.parse(levelStr);
    final name = cols[1].trim();
    final theme = cols[2].trim();

    // +0행은 성공률/강화비용/판매가가 '-'
    final successRateRaw = cols[3].trim();
    final double? successRate = successRateRaw == '-'
        ? null
        : double.parse(successRateRaw) / 100.0;

    final enhanceCostRaw = cols[4].trim();
    final int enhanceCost =
        enhanceCostRaw == '-' ? 0 : int.parse(enhanceCostRaw);

    final totalInvestmentRaw = cols[5].trim();
    final int totalInvestment =
        totalInvestmentRaw == '-' ? 0 : int.parse(totalInvestmentRaw);

    final sellPriceRaw = cols[6].trim();
    final int? sellPrice =
        sellPriceRaw == '-' ? null : int.parse(sellPriceRaw);

    final returnRateRaw = cols[7].trim().replaceAll('%', '');
    final double? returnRate =
        returnRateRaw == '-' ? null : double.parse(returnRateRaw) / 100.0;

    final fragmentRaw = cols[8].trim();
    final int fragmentReward =
        fragmentRaw == '-' ? 0 : int.parse(fragmentRaw);

    final collectibleRaw = cols[9].trim().toUpperCase();
    final bool collectible = collectibleRaw == 'Y';

    return Sword(
      level: level,
      name: name,
      theme: theme,
      successRate: successRate,
      enhanceCost: enhanceCost,
      totalInvestment: totalInvestment,
      sellPrice: sellPrice,
      returnRate: returnRate,
      fragmentReward: fragmentReward,
      collectible: collectible,
    );
  }
}
