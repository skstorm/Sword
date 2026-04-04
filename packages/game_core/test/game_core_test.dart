import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('SwordDataLoader', () {
    late SwordDataLoader loader;

    setUp(() {
      loader = SwordDataLoader();
    });

    const testCsv = '''강화,검 이름,테마,성공률(%),강화비용,누적투자,판매가,회수율,파괴시파편,수집가능
+0,나무검,기본,-,0,0,-,-,-,N
+1,철검,기본,95,5,5,4,70%,1,N
+2,강철검,기본,92,8,13,10,75%,1,N
+10,엑스칼리버,아서왕 전설,35,270,775,850,110%,8,Y
+20,■■■■■■의 검 [데이터 삭제됨],뇌절(최종),0.1,30000,66975,133950,200%,50,Y''';

    test('헤더를 스킵하고 올바른 수의 검을 파싱한다', () {
      final swords = loader.parse(testCsv);
      expect(swords.length, 5);
    });

    test('+0 나무검의 성공률/판매가는 null이다', () {
      final swords = loader.parse(testCsv);
      final wooden = swords[0];
      expect(wooden.level, 0);
      expect(wooden.name, '나무검');
      expect(wooden.successRate, isNull);
      expect(wooden.enhanceCost, 0);
      expect(wooden.sellPrice, isNull);
      expect(wooden.returnRate, isNull);
      expect(wooden.fragmentReward, 0);
      expect(wooden.collectible, false);
    });

    test('+1 철검의 성공률은 0.95이다', () {
      final swords = loader.parse(testCsv);
      final iron = swords[1];
      expect(iron.level, 1);
      expect(iron.name, '철검');
      expect(iron.successRate, closeTo(0.95, 0.001));
      expect(iron.enhanceCost, 5);
      expect(iron.sellPrice, 4);
      expect(iron.collectible, false);
    });

    test('+10 엑스칼리버는 수집 가능하다', () {
      final swords = loader.parse(testCsv);
      final excalibur = swords[3];
      expect(excalibur.level, 10);
      expect(excalibur.name, '엑스칼리버');
      expect(excalibur.successRate, closeTo(0.35, 0.001));
      expect(excalibur.sellPrice, 850);
      expect(excalibur.fragmentReward, 8);
      expect(excalibur.collectible, true);
    });

    test('+20 최종검의 성공률은 0.001이다', () {
      final swords = loader.parse(testCsv);
      final last = swords[4];
      expect(last.level, 20);
      expect(last.successRate, closeTo(0.001, 0.0001));
      expect(last.sellPrice, 133950);
      expect(last.fragmentReward, 50);
      expect(last.collectible, true);
    });

    test('빈 CSV는 빈 리스트를 반환한다', () {
      expect(loader.parse(''), isEmpty);
    });

    test('헤더만 있으면 빈 리스트를 반환한다', () {
      expect(loader.parse('강화,검 이름,테마,성공률(%),강화비용,누적투자,판매가,회수율,파괴시파편,수집가능'), isEmpty);
    });

    test('SwordDataTable 레벨 조회가 동작한다', () {
      final swords = loader.parse(testCsv);
      final table = SwordDataTable(swords);
      expect(table.getSword(0)?.name, '나무검');
      expect(table.getSword(1)?.name, '철검');
      expect(table.getSword(99), isNull);
    });

    test('SwordDataTable collectibleSwords 필터가 동작한다', () {
      final swords = loader.parse(testCsv);
      final table = SwordDataTable(swords);
      final collectibles = table.collectibleSwords;
      expect(collectibles.length, 2);
      expect(collectibles[0].name, '엑스칼리버');
    });
  });

  group('MasteryDataLoader', () {
    late MasteryDataLoader loader;

    setUp(() {
      loader = MasteryDataLoader();
    });

    const testCsv = '''레벨,필요경험치,비용할인율,파편보너스,외형ID,보상설명
1,0,0,0,workshop_basic,초보 장인
2,50,0.05,0,workshop_basic,강화 비용 5% 할인
7,3000,0.15,1,workshop_furnace,파편 획득량 +1
10,15000,0.25,1,workshop_legend,강화 비용 25% 할인 + 전용 칭호 마스터 스미스''';

    test('올바른 수의 레벨을 파싱한다', () {
      final levels = loader.parse(testCsv);
      expect(levels.length, 4);
    });

    test('Lv.1은 할인 0, 파편보너스 0이다', () {
      final levels = loader.parse(testCsv);
      expect(levels[0].level, 1);
      expect(levels[0].requiredExp, 0);
      expect(levels[0].costDiscount, 0);
      expect(levels[0].fragmentBonus, 0);
    });

    test('Lv.7은 파편보너스 1이다', () {
      final levels = loader.parse(testCsv);
      expect(levels[2].fragmentBonus, 1);
      expect(levels[2].costDiscount, closeTo(0.15, 0.001));
    });

    test('MasteryLevelTable 경험치 → 레벨 변환이 동작한다', () {
      final levels = loader.parse(testCsv);
      final table = MasteryLevelTable(levels);
      expect(table.getLevelForExp(0), 1);
      expect(table.getLevelForExp(49), 1);
      expect(table.getLevelForExp(50), 2);
      expect(table.getLevelForExp(2999), 2);
      expect(table.getLevelForExp(3000), 7);
      expect(table.getLevelForExp(15000), 10);
    });
  });
}
