import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';

// Import logic classes directly (not exported)
import 'package:game_core/logic/game_session_logic.dart';

void main() {
  group('GameSessionLogic', () {
    late GameSessionLogic logic;
    late SwordDataTable swordTable;

    setUp(() {
      logic = GameSessionLogic();
      swordTable = createTestSwordTable();
    });

    group('createInitialState', () {
      test('starts with wooden sword at level 0', () {
        final playerData = PlayerData(gold: 50);

        final state = logic.createInitialState(playerData, swordTable);

        expect(state.currentLevel, equals(0));
        expect(state.currentSword.name, equals('나무검'));
        expect(state.currentSword.level, equals(0));
      });

      test('grants 200 gold when isFirstRun is true', () {
        final playerData = PlayerData(gold: 0, isFirstRun: true);

        final state = logic.createInitialState(playerData, swordTable);

        expect(state.playerData.gold, equals(200));
        expect(state.playerData.isFirstRun, isFalse);
      });

      test('does not change gold when isFirstRun is false', () {
        final playerData = PlayerData(gold: 500, isFirstRun: false);

        final state = logic.createInitialState(playerData, swordTable);

        expect(state.playerData.gold, equals(500));
        expect(state.playerData.isFirstRun, isFalse);
      });

      test('initializes with no active modifiers', () {
        final playerData = PlayerData(gold: 100);

        final state = logic.createInitialState(playerData, swordTable);

        expect(state.activeModifiers, isEmpty);
      });

      test('initializes with no protection flags', () {
        final playerData = PlayerData(gold: 100);

        final state = logic.createInitialState(playerData, swordTable);

        expect(state.hasActiveProtection, isFalse);
        expect(state.pendingAdProtection, isFalse);
      });

      test('preserves other player data when first run', () {
        final playerData = PlayerData(
          gold: 0,
          isFirstRun: true,
          fragments: 10,
          stats: Statistics(totalDestroys: 5),
        );

        final state = logic.createInitialState(playerData, swordTable);

        expect(state.playerData.fragments, equals(10));
        expect(state.playerData.stats.totalDestroys, equals(5));
      });
    });

    group('resetToWoodenSword', () {
      test('resets to level 0 wooden sword', () {
        final currentState = createTestState(
          level: 10,
          gold: 500,
          swordTable: swordTable,
        );

        final newState = logic.resetToWoodenSword(currentState, swordTable);

        expect(newState.currentLevel, equals(0));
        expect(newState.currentSword.name, equals('나무검'));
        expect(newState.currentSword.level, equals(0));
      });

      test('clears active modifiers', () {
        final modifier = _TestModifier(0.1);
        final currentState = createTestState(
          level: 5,
          gold: 500,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );

        final newState = logic.resetToWoodenSword(currentState, swordTable);

        expect(newState.activeModifiers, isEmpty);
      });

      test('clears hasActiveProtection', () {
        final currentState = createTestState(
          level: 5,
          gold: 500,
          swordTable: swordTable,
          hasActiveProtection: true,
        );

        final newState = logic.resetToWoodenSword(currentState, swordTable);

        expect(newState.hasActiveProtection, isFalse);
      });

      test('clears pendingAdProtection', () {
        final currentState = createTestState(
          level: 5,
          gold: 500,
          swordTable: swordTable,
          pendingAdProtection: true,
        );

        final newState = logic.resetToWoodenSword(currentState, swordTable);

        expect(newState.pendingAdProtection, isFalse);
      });

      test('preserves player data', () {
        final currentState = createTestState(
          level: 10,
          gold: 500,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 500,
            fragments: 25,
            stats: Statistics(totalDestroys: 3, totalSells: 7),
          ),
        );

        final newState = logic.resetToWoodenSword(currentState, swordTable);

        expect(newState.playerData.gold, equals(500));
        expect(newState.playerData.fragments, equals(25));
        expect(newState.playerData.stats.totalDestroys, equals(3));
        expect(newState.playerData.stats.totalSells, equals(7));
      });

      test('can be called from level 0 (idempotent)', () {
        final currentState = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );

        final newState = logic.resetToWoodenSword(currentState, swordTable);

        expect(newState.currentLevel, equals(0));
        expect(newState.currentSword.name, equals('나무검'));
      });
    });
  });
}

// Test modifier implementation
class _TestModifier implements Modifier {
  final double delta;
  _TestModifier(this.delta);

  @override
  double apply(double baseRate) => baseRate + delta;
}
