import '../models/mastery.dart';

/// mastery_levels.csv 파서
class MasteryDataLoader {
  List<MasteryLevel> parse(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final levels = <MasteryLevel>[];
    for (var i = 1; i < lines.length; i++) {
      try {
        final level = _parseLine(lines[i]);
        if (level != null) levels.add(level);
      } catch (_) {
        // 파싱 실패 시 해당 행 스킵
      }
    }
    return levels;
  }

  MasteryLevel? _parseLine(String line) {
    final cols = line.split(',');
    if (cols.length < 6) return null;

    return MasteryLevel(
      level: int.parse(cols[0].trim()),
      requiredExp: int.parse(cols[1].trim()),
      costDiscount: double.parse(cols[2].trim()),
      fragmentBonus: int.parse(cols[3].trim()),
      visualId: cols[4].trim(),
      rewardDescription: cols[5].trim(),
    );
  }
}
