import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';

void main() {
  group('SellCommand', () {
    late SwordDataTable swordTable;
    late MasteryLevelTable masteryTable;

    setUp(() {
      swordTable = createTestSwordTable();
      masteryTable = createTestMasteryTable();
    });

    group('validate', () {
      test('rejects selling wooden sword (level 0)', () {
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final rejection = command.validate(state, context);

        expect(rejection, equals('cannot_sell_wooden_sword'));
      });

      test('rejects when pendingAdProtection is true', () {
        final state = createTestState(
          level: 5,
          gold: 100,
          pendingAdProtection: true,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final rejection = command.validate(state, context);

        expect(rejection, equals('pending_ad_protection'));
      });

      test('accepts selling non-wooden sword', () {
        final state = createTestState(
          level: 1,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final rejection = command.validate(state, context);

        expect(rejection, isNull);
      });
    });

    group('execute', () {
      test('gains gold equal to sword sell price', () {
        final state = createTestState(
          level: 5, // 황금검, sell price 60
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.gold, equals(160)); // 100 + 60
      });

      test('sell price matches CSV data', () {
        final state = createTestState(
          level: 10, // 엑스칼리버, sell price 850
          gold: 0,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.gold, equals(850));

        final goldEvent = result.events.whereType<GoldChangeEvent>().first;
        expect(goldEvent.amount, equals(850));
        expect(goldEvent.reason, equals('sell'));
      });

      test('resets to wooden sword after sell', () {
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.currentLevel, equals(0));
        expect(result.newState.currentSword.name, equals('나무검'));
      });

      test('clears active modifiers after sell', () {
        final modifier = _TestModifier(0.1);
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.activeModifiers, isEmpty);
      });

      test('clears protection flags after sell', () {
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          hasActiveProtection: true,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.hasActiveProtection, isFalse);
        expect(result.newState.pendingAdProtection, isFalse);
      });

      test('updates totalSells stat', () {
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 100,
            stats: Statistics(totalSells: 3),
          ),
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.stats.totalSells, equals(4));
      });

      test('updates totalGoldEarned stat', () {
        final state = createTestState(
          level: 5, // Sell price 60
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 100,
            stats: Statistics(totalGoldEarned: 200),
          ),
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.stats.totalGoldEarned, equals(260)); // 200 + 60
      });

      test('emits SellEvent with correct data', () {
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        final sellEvent = result.events.whereType<SellEvent>().first;
        expect(sellEvent.soldLevel, equals(5));
        expect(sellEvent.soldSwordName, equals('황금검'));
        expect(sellEvent.goldGained, equals(60));
      });

      test('emits both GoldChangeEvent and SellEvent', () {
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = SellCommand();

        final result = command.execute(state, context);

        expect(result.events.length, equals(2));
        expect(result.events[0], isA<GoldChangeEvent>());
        expect(result.events[1], isA<SellEvent>());
      });

      test('correct sell prices for various levels', () {
        // Test multiple levels to verify CSV data
        final testCases = [
          (1, 4), // 철검
          (2, 10), // 강철검
          (3, 19), // 청동검
          (10, 850), // 엑스칼리버
          (20, 133950), // 최종검
        ];

        for (final (level, expectedPrice) in testCases) {
          final state = createTestState(
            level: level,
            gold: 0,
            swordTable: swordTable,
          );
          final context = createTestContext(
            swordTable: swordTable,
            masteryTable: masteryTable,
          );
          final command = SellCommand();

          final result = command.execute(state, context);

          expect(
            result.newState.playerData.gold,
            equals(expectedPrice),
            reason: 'Level $level should sell for $expectedPrice gold',
          );
        }
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
