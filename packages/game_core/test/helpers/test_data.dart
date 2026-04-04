import 'package:game_core/game_core.dart';
import 'fake_random_provider.dart';
import 'fake_time_provider.dart';

const testSwordsCsv = '''강화,검 이름,테마,성공률(%),강화비용,누적투자,판매가,회수율,파괴시파편,수집가능
+0,나무검,기본,-,0,0,-,-,-,N
+1,철검,기본,95,5,5,4,70%,1,N
+2,강철검,기본,92,8,13,10,75%,1,N
+3,청동검,기본,88,12,25,19,76%,1,N
+4,백은검,기본,83,20,45,34,78%,1,N
+5,황금검,기본,77,30,75,60,80%,1,N
+6,미스릴검,판타지,70,50,125,100,80%,3,N
+7,크리스탈 소드,판타지,62,80,205,170,83%,3,N
+8,룬소드,판타지,53,120,325,295,91%,3,N
+9,다마스쿠스 블레이드,역사,44,180,505,505,100%,3,N
+10,엑스칼리버,아서왕 전설,35,270,775,850,110%,8,Y
+11,그람 (시그문드의 검),북유럽 신화,27,400,1175,1410,120%,8,Y
+12,천총운검,한국 신화,20,600,1775,2310,130%,8,Y
+13,쿠사나기노츠루기,일본 신화,14,900,2675,4010,150%,8,Y
+14,듀랑달,샤를마뉴 전설,10,1300,3975,6360,160%,8,Y
+15,참마도,한국 고전(전우치전),7,2000,5975,10160,170%,20,Y
+16,레바테인,북유럽 신화,4.5,3000,8975,16160,180%,20,Y
+17,에아 (천지괴리개벽의 별),서브컬쳐,2.5,5000,13975,27950,200%,20,Y
+18,초차원 드래곤슬레이어 DX,뇌절,1.2,8000,21975,43950,200%,50,Y
+19,울트라 킹왕짱 투명드래곤의 검,뇌절,0.5,15000,36975,73950,200%,50,Y
+20,■■■■■■의 검 [데이터 삭제됨],뇌절(최종),0.1,30000,66975,133950,200%,50,Y''';

const testMasteryCsv = '''레벨,필요경험치,비용할인율,파편보너스,외형ID,보상설명
1,0,0,0,workshop_basic,초보 장인
2,50,0.05,0,workshop_basic,강화 비용 5% 할인
3,150,0.05,0,workshop_basic,+1~+3 강화 연출 스킵 옵션
4,400,0.10,0,workshop_basic,강화 비용 10% 할인
5,800,0.10,0,workshop_furnace,공방 외형 변경
6,1500,0.15,0,workshop_furnace,강화 비용 15% 할인
7,3000,0.15,1,workshop_furnace,파편 획득량 +1
8,5000,0.20,1,workshop_furnace,강화 비용 20% 할인
9,8000,0.20,1,workshop_legend,공방 외형 변경
10,15000,0.25,1,workshop_legend,강화 비용 25% 할인''';

/// Create test sword data table
SwordDataTable createTestSwordTable() {
  final loader = SwordDataLoader();
  final swords = loader.parse(testSwordsCsv);
  return SwordDataTable(swords);
}

/// Create test mastery level table
MasteryLevelTable createTestMasteryTable() {
  final loader = MasteryDataLoader();
  final levels = loader.parse(testMasteryCsv);
  return MasteryLevelTable(levels);
}

/// Create test game context with fake providers
GameContext createTestContext({
  RandomProvider? random,
  TimeProvider? time,
  SwordDataTable? swordTable,
  MasteryLevelTable? masteryTable,
}) {
  return GameContext(
    random: random ?? FakeRandomProvider(),
    time: time ?? FakeTimeProvider(),
    swordTable: swordTable ?? createTestSwordTable(),
    masteryTable: masteryTable ?? createTestMasteryTable(),
  );
}

/// Create test game state at specific level with optional gold
GameState createTestState({
  int level = 0,
  int gold = 1000,
  SwordDataTable? swordTable,
  bool hasActiveProtection = false,
  bool pendingAdProtection = false,
  List<Modifier> activeModifiers = const [],
  PlayerData? playerData,
}) {
  final table = swordTable ?? createTestSwordTable();
  final sword = table.getSword(level)!;

  final basePlayerData = playerData ?? PlayerData(gold: gold);

  return GameState(
    currentSword: sword,
    currentLevel: level,
    playerData: basePlayerData,
    hasActiveProtection: hasActiveProtection,
    pendingAdProtection: pendingAdProtection,
    activeModifiers: activeModifiers,
  );
}
