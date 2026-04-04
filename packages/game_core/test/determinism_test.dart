import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';
import 'helpers/fake_time_provider.dart';

void main() {
  group('Determinism Tests', () {
    late SwordDataTable swordTable;
    late MasteryLevelTable masteryTable;

    setUp(() {
      swordTable = createTestSwordTable();
      masteryTable = createTestMasteryTable();
    });

    test('Same seed produces identical results', () {
      const seed = 42;
      const initialGold = 10000;

      // First run
      final random1 = FakeRandomProvider.seeded(seed);
      final time1 = FakeTimeProvider(DateTime(2025, 1, 1));
      final initialState1 = createTestState(
        level: 0,
        gold: initialGold,
        swordTable: swordTable,
      );
      final context1 = createTestContext(
        random: random1,
        time: time1,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine1 = GameEngine(
        initialState: initialState1,
        context: context1,
      );

      // Second run with same seed
      final random2 = FakeRandomProvider.seeded(seed);
      final time2 = FakeTimeProvider(DateTime(2025, 1, 1));
      final initialState2 = createTestState(
        level: 0,
        gold: initialGold,
        swordTable: swordTable,
      );
      final context2 = createTestContext(
        random: random2,
        time: time2,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine2 = GameEngine(
        initialState: initialState2,
        context: context2,
      );

      // Execute same sequence of commands
      final commands = [
        EnhanceCommand(), // +1
        EnhanceCommand(), // +2
        EnhanceCommand(), // +3
        EnhanceCommand(), // +4
        EnhanceCommand(), // +5
        SellCommand(), // Sell
        EnhanceCommand(), // +1 again
        EnhanceCommand(), // +2 again
        EnhanceCommand(), // +3 again
        EnhanceCommand(), // +4 again
      ];

      for (final command in commands) {
        engine1.dispatch(command);
      }

      for (final command in commands) {
        engine2.dispatch(command);
      }

      // Compare final states
      expect(engine1.state.currentLevel, equals(engine2.state.currentLevel));
      expect(engine1.state.currentSword.name, equals(engine2.state.currentSword.name));
      expect(engine1.state.playerData.gold, equals(engine2.state.playerData.gold));
      expect(engine1.state.playerData.fragments, equals(engine2.state.playerData.fragments));
      expect(engine1.state.playerData.stats.totalEnhanceAttempts,
          equals(engine2.state.playerData.stats.totalEnhanceAttempts));
      expect(engine1.state.playerData.stats.totalDestroys,
          equals(engine2.state.playerData.stats.totalDestroys));
      expect(engine1.state.playerData.stats.totalSells,
          equals(engine2.state.playerData.stats.totalSells));
      expect(engine1.state.playerData.stats.highestEnhanceLevel,
          equals(engine2.state.playerData.stats.highestEnhanceLevel));

      engine1.dispose();
      engine2.dispose();
    });

    test('Different seeds produce different results', () {
      const initialGold = 10000;

      // First run with seed 42
      final random1 = FakeRandomProvider.seeded(42);
      final initialState1 = createTestState(
        level: 0,
        gold: initialGold,
        swordTable: swordTable,
      );
      final context1 = createTestContext(
        random: random1,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine1 = GameEngine(
        initialState: initialState1,
        context: context1,
      );

      // Second run with seed 999
      final random2 = FakeRandomProvider.seeded(999);
      final initialState2 = createTestState(
        level: 0,
        gold: initialGold,
        swordTable: swordTable,
      );
      final context2 = createTestContext(
        random: random2,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine2 = GameEngine(
        initialState: initialState2,
        context: context2,
      );

      // Execute same commands
      final commands = List.generate(20, (_) => EnhanceCommand());

      for (final command in commands) {
        engine1.dispatch(command);
      }

      for (final command in commands) {
        engine2.dispatch(command);
      }

      // At least one of these should be different
      final isDifferent = engine1.state.currentLevel != engine2.state.currentLevel ||
          engine1.state.playerData.gold != engine2.state.playerData.gold ||
          engine1.state.playerData.stats.totalDestroys !=
              engine2.state.playerData.stats.totalDestroys;

      expect(isDifferent, isTrue,
          reason: 'Different seeds should produce different outcomes');

      engine1.dispose();
      engine2.dispose();
    });

    test('Complex sequence is deterministic', () {
      const seed = 12345;
      const initialGold = 50000;

      // First run
      final random1 = FakeRandomProvider.seeded(seed);
      final time1 = FakeTimeProvider(DateTime(2025, 6, 15));
      final initialState1 = createTestState(
        level: 0,
        gold: initialGold,
        swordTable: swordTable,
      );
      final context1 = createTestContext(
        random: random1,
        time: time1,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine1 = GameEngine(
        initialState: initialState1,
        context: context1,
      );

      // Second run
      final random2 = FakeRandomProvider.seeded(seed);
      final time2 = FakeTimeProvider(DateTime(2025, 6, 15));
      final initialState2 = createTestState(
        level: 0,
        gold: initialGold,
        swordTable: swordTable,
      );
      final context2 = createTestContext(
        random: random2,
        time: time2,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine2 = GameEngine(
        initialState: initialState2,
        context: context2,
      );

      // Complex sequence: enhance until fail or high level, then sell, repeat
      final commands = <Command>[];
      for (int i = 0; i < 10; i++) {
        // Try to enhance 5 times
        for (int j = 0; j < 5; j++) {
          commands.add(EnhanceCommand());
        }
        // Sell (might be rejected if at level 0)
        commands.add(SellCommand());
      }

      // Execute both
      for (final command in commands) {
        engine1.dispatch(command);
      }

      for (final command in commands) {
        engine2.dispatch(command);
      }

      // Deep comparison
      final state1 = engine1.state;
      final state2 = engine2.state;

      expect(state1.currentLevel, equals(state2.currentLevel),
          reason: 'Current level should match');
      expect(state1.currentSword.name, equals(state2.currentSword.name),
          reason: 'Current sword name should match');
      expect(state1.playerData.gold, equals(state2.playerData.gold),
          reason: 'Gold should match');
      expect(state1.playerData.fragments, equals(state2.playerData.fragments),
          reason: 'Fragments should match');

      // Stats comparison
      expect(state1.playerData.stats.totalEnhanceAttempts,
          equals(state2.playerData.stats.totalEnhanceAttempts),
          reason: 'Total enhance attempts should match');
      expect(state1.playerData.stats.totalDestroys,
          equals(state2.playerData.stats.totalDestroys),
          reason: 'Total destroys should match');
      expect(state1.playerData.stats.totalSells,
          equals(state2.playerData.stats.totalSells),
          reason: 'Total sells should match');
      expect(state1.playerData.stats.totalGoldEarned,
          equals(state2.playerData.stats.totalGoldEarned),
          reason: 'Total gold earned should match');
      expect(state1.playerData.stats.highestEnhanceLevel,
          equals(state2.playerData.stats.highestEnhanceLevel),
          reason: 'Highest enhance level should match');
      expect(state1.playerData.stats.currentConsecutiveSuccess,
          equals(state2.playerData.stats.currentConsecutiveSuccess),
          reason: 'Current consecutive success should match');
      expect(state1.playerData.stats.currentConsecutiveFail,
          equals(state2.playerData.stats.currentConsecutiveFail),
          reason: 'Current consecutive fail should match');
      expect(state1.playerData.stats.maxConsecutiveSuccess,
          equals(state2.playerData.stats.maxConsecutiveSuccess),
          reason: 'Max consecutive success should match');
      expect(state1.playerData.stats.maxConsecutiveFail,
          equals(state2.playerData.stats.maxConsecutiveFail),
          reason: 'Max consecutive fail should match');

      engine1.dispose();
      engine2.dispose();
    });

    test('Determinism maintained across rejected commands', () {
      const seed = 7777;

      final random1 = FakeRandomProvider.seeded(seed);
      final initialState1 = createTestState(
        level: 0,
        gold: 20, // Limited gold
        swordTable: swordTable,
      );
      final context1 = createTestContext(
        random: random1,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine1 = GameEngine(
        initialState: initialState1,
        context: context1,
      );

      final random2 = FakeRandomProvider.seeded(seed);
      final initialState2 = createTestState(
        level: 0,
        gold: 20,
        swordTable: swordTable,
      );
      final context2 = createTestContext(
        random: random2,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );
      final engine2 = GameEngine(
        initialState: initialState2,
        context: context2,
      );

      // Try to enhance many times (will run out of gold)
      final commands = List.generate(10, (_) => EnhanceCommand());

      for (final command in commands) {
        engine1.dispatch(command);
      }

      for (final command in commands) {
        engine2.dispatch(command);
      }

      expect(engine1.state.currentLevel, equals(engine2.state.currentLevel));
      expect(engine1.state.playerData.gold, equals(engine2.state.playerData.gold));

      engine1.dispose();
      engine2.dispose();
    });
  });
}
