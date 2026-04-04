import 'package:test/test.dart';
import 'package:game_core/game_core.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';

void main() {
  group('Mastery System', () {
    late SwordDataTable swordTable;
    late MasteryLevelTable masteryTable;

    setUp(() {
      swordTable = createTestSwordTable();
      masteryTable = createTestMasteryTable();
    });

    group('Experience Gain', () {
      test('mastery exp increases by 1 per enhance attempt', () async {
        final random = FakeRandomProvider(0.1); // Always success
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 0,
          gold: 10000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);

        // Execute 5 enhance attempts
        for (int i = 0; i < 5; i++) {
          engine.dispatch(EnhanceCommand());
        }
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.mastery.totalAttempts, equals(5));
        engine.dispose();
      });

      test('mastery exp increases even on failed attempts', () async {
        final random = FakeRandomProvider(0.99); // Always fail
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 5,
          gold: 10000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 10000,
            adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)), // Prevent pendingAdProtection
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        // Execute 3 enhance attempts (all will fail, each time resets to wooden)
        for (int i = 0; i < 3; i++) {
          engine.dispatch(EnhanceCommand());
        }
        await Future.delayed(Duration(milliseconds: 10));

        // First fails at level 5 → reset to 0, second fails at level 0→1 (0.99>=0.95), third same
        expect(engine.state.playerData.mastery.totalAttempts, equals(3));
        engine.dispose();
      });
    });

    group('Level Up', () {
      test('mastery level up at 50 attempts emits MasteryLevelUpEvent', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 0,
          gold: 50000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 50000,
            mastery: MasteryData(level: 1, totalAttempts: 48),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        // Execute 2 more attempts to reach 50
        engine.dispatch(EnhanceCommand());
        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.mastery.level, equals(2));
        expect(engine.state.playerData.mastery.totalAttempts, equals(50));

        final levelUpEvents = events.whereType<MasteryLevelUpEvent>().toList();
        expect(levelUpEvents.length, equals(1));
        expect(levelUpEvents.first.newLevel, equals(2));
        expect(levelUpEvents.first.reward, isNotNull);
        engine.dispose();
      });

      test('no level up event when exp does not reach threshold', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 0,
          gold: 10000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 10000,
            mastery: MasteryData(level: 1, totalAttempts: 45),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        // Execute 3 attempts (total 48, not enough for level 2)
        for (int i = 0; i < 3; i++) {
          engine.dispatch(EnhanceCommand());
        }
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.mastery.level, equals(1));
        expect(engine.state.playerData.mastery.totalAttempts, equals(48));

        final levelUpEvents = events.whereType<MasteryLevelUpEvent>();
        expect(levelUpEvents.isEmpty, isTrue);
        engine.dispose();
      });

      test('multiple level ups in sequence', () async {
        final random = FakeRandomProvider(0.01); // Always success up to very high levels
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 0,
          gold: 9999999,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 9999999,
            mastery: MasteryData(level: 1, totalAttempts: 0),
            adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        // Execute 200 attempts (success and fail mix, but mastery always increments)
        for (int i = 0; i < 200; i++) {
          engine.dispatch(EnhanceCommand());
        }
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.mastery.totalAttempts, equals(200));
        expect(engine.state.playerData.mastery.level, greaterThanOrEqualTo(3));

        final levelUpEvents = events.whereType<MasteryLevelUpEvent>().toList();
        expect(levelUpEvents.length, greaterThanOrEqualTo(2));
        engine.dispose();
      });
    });

    group('Cost Discount', () {
      test('5% cost discount applied at mastery level 2', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 0,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            mastery: MasteryData(level: 2, totalAttempts: 50),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // Base cost for +1 is 5, with 5% discount = 4.75 -> floor = 4
        expect(engine.state.playerData.gold, equals(996)); // 1000 - 4
        engine.dispose();
      });

      test('10% cost discount applied at mastery level 4', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 1,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            mastery: MasteryData(level: 4, totalAttempts: 400),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // Base cost for +2 is 8, with 10% discount = 7.2 -> floor = 7
        expect(engine.state.playerData.gold, equals(993)); // 1000 - 7
        engine.dispose();
      });

      test('25% cost discount applied at mastery level 10', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 5,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            mastery: MasteryData(level: 10, totalAttempts: 15000),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // Base cost for +6 is 50, with 25% discount = 37.5 -> floor = 37
        expect(engine.state.playerData.gold, equals(963)); // 1000 - 37
        engine.dispose();
      });
    });

    group('Fragment Bonus', () {
      test('fragment bonus +1 at mastery level 7', () async {
        final random = FakeRandomProvider(0.99); // Fail
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 5,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            fragments: 0,
            mastery: MasteryData(level: 7, totalAttempts: 3000),
            adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // +5 황금검 base fragments: 1, bonus: 1, total: 2
        expect(engine.state.playerData.fragments, equals(2));
        engine.dispose();
      });

      test('fragment bonus +1 at mastery level 9', () async {
        final random = FakeRandomProvider(0.99);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 6,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            fragments: 10,
            mastery: MasteryData(level: 9, totalAttempts: 8000),
            adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // +6 미스릴검 base fragments: 3, bonus: 1, total: 4
        expect(engine.state.playerData.fragments, equals(14)); // 10 + 4
        engine.dispose();
      });

      test('no fragment bonus at mastery level 6', () async {
        final random = FakeRandomProvider(0.99);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 5,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            fragments: 0,
            mastery: MasteryData(level: 6, totalAttempts: 1500),
            adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // +5 황금검 base fragments: 1, no bonus at level 6
        expect(engine.state.playerData.fragments, equals(1));
        engine.dispose();
      });
    });
  });
}
