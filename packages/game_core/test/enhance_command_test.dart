import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';

void main() {
  group('EnhanceCommand', () {
    late SwordDataTable swordTable;
    late MasteryLevelTable masteryTable;

    setUp(() {
      swordTable = createTestSwordTable();
      masteryTable = createTestMasteryTable();
    });

    group('validate', () {
      test('rejects when pendingAdProtection is true', () {
        final state = createTestState(
          level: 5,
          gold: 1000,
          pendingAdProtection: true,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final rejection = command.validate(state, context);

        expect(rejection, equals('pending_ad_protection'));
      });

      test('rejects when insufficient gold', () {
        final state = createTestState(
          level: 0,
          gold: 2, // Need 5 for +1
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final rejection = command.validate(state, context);

        expect(rejection, equals('insufficient_gold'));
      });

      test('rejects when at max level', () {
        final state = createTestState(
          level: 20,
          gold: 99999,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final rejection = command.validate(state, context);

        expect(rejection, equals('max_level_reached'));
      });

      test('accepts valid enhance attempt', () {
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final rejection = command.validate(state, context);

        expect(rejection, isNull);
      });
    });

    group('execute - success', () {
      test('deducts gold before enhancing', () {
        final random = FakeRandomProvider(0.1); // Success (< 0.95)
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.gold, equals(95)); // 100 - 5
        // Check GoldChangeEvent was emitted
        final goldEvent = result.events.whereType<GoldChangeEvent>().first;
        expect(goldEvent.amount, equals(-5));
        expect(goldEvent.newTotal, equals(95));
      });

      test('upgrades to next level on success', () {
        final random = FakeRandomProvider(0.1); // Success
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.currentLevel, equals(1));
        expect(result.newState.currentSword.name, equals('철검'));
      });

      test('updates highestLevel stat on success', () {
        final random = FakeRandomProvider(0.1);
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(gold: 100),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.stats.highestEnhanceLevel, equals(1));
      });

      test('increments consecutiveSuccess and resets consecutiveFail', () {
        final random = FakeRandomProvider(0.1);
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 100,
            stats: Statistics(
              currentConsecutiveSuccess: 2,
              currentConsecutiveFail: 1,
            ),
          ),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.stats.currentConsecutiveSuccess, equals(3));
        expect(result.newState.playerData.stats.currentConsecutiveFail, equals(0));
        expect(result.newState.playerData.stats.maxConsecutiveSuccess, equals(3));
      });

      test('emits EnhanceSuccessEvent on success', () {
        final random = FakeRandomProvider(0.1);
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        final successEvent = result.events.whereType<EnhanceSuccessEvent>().first;
        expect(successEvent.prevLevel, equals(0));
        expect(successEvent.newLevel, equals(1));
        expect(successEvent.newSwordName, equals('철검'));
      });
    });

    group('execute - fail', () {
      test('deducts gold even on fail', () {
        final random = FakeRandomProvider(0.96); // Fail (>= 0.95)
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.gold, equals(95)); // 100 - 5
      });

      test('destroys sword on fail without protection', () {
        final random = FakeRandomProvider(0.96); // Fail
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          hasActiveProtection: false,
          playerData: PlayerData(
            gold: 100,
            adLimits: AdLimits(adProtectionUsedToday: 2), // No ad available
          ),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        // Should reset to wooden sword when no ad protection available
        expect(result.newState.currentLevel, equals(0));
        expect(result.newState.currentSword.name, equals('나무검'));
        expect(result.newState.pendingAdProtection, isFalse);
      });

      test('increments totalDestroys stat on destruction', () {
        final random = FakeRandomProvider(0.96);
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 100,
            stats: Statistics(totalDestroys: 3),
          ),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.stats.totalDestroys, equals(4));
      });

      test('increments consecutiveFail and resets consecutiveSuccess', () {
        final random = FakeRandomProvider(0.96);
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 100,
            stats: Statistics(
              currentConsecutiveSuccess: 2,
              currentConsecutiveFail: 1,
            ),
          ),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        expect(result.newState.playerData.stats.currentConsecutiveFail, equals(2));
        expect(result.newState.playerData.stats.currentConsecutiveSuccess, equals(0));
        expect(result.newState.playerData.stats.maxConsecutiveFail, equals(2));
      });

      test('emits EnhanceFailEvent on fail', () {
        final random = FakeRandomProvider(0.96);
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        final failEvent = result.events.whereType<EnhanceFailEvent>().first;
        expect(failEvent.destroyedLevel, equals(5));
        expect(failEvent.destroyedSwordName, equals('황금검'));
        expect(failEvent.destroyed, isTrue);
      });

      test('does not destroy with active protection', () {
        final random = FakeRandomProvider(0.96);
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          hasActiveProtection: true,
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        // 보호 부적이 파괴를 막았으므로 레벨 유지
        expect(result.newState.currentLevel, equals(5));
        expect(result.newState.currentSword.name, equals('황금검'));
        expect(result.newState.hasActiveProtection, isFalse); // 부적 소모됨

        final failEvent = result.events.whereType<EnhanceFailEvent>().first;
        expect(failEvent.destroyed, isFalse); // Event correctly reports not destroyed

        // Should not increment totalDestroys when protected (this works correctly)
        expect(result.newState.playerData.stats.totalDestroys, equals(0));
      });

      test('sets pendingAdProtection but does not reset when ad available', () {
        final random = FakeRandomProvider(0.96);
        final state = createTestState(
          level: 5,
          gold: 100,
          swordTable: swordTable,
          hasActiveProtection: false,
          playerData: PlayerData(
            gold: 100,
            adLimits: AdLimits(adProtectionUsedToday: 0), // Ad available
          ),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        // Should NOT reset to wooden sword yet (waiting for ad choice)
        expect(result.newState.currentLevel, equals(5));
        expect(result.newState.currentSword.name, equals('황금검'));
        expect(result.newState.pendingAdProtection, isTrue);

        final failEvent = result.events.whereType<EnhanceFailEvent>().first;
        expect(failEvent.destroyed, isTrue);
        expect(failEvent.adProtectionAvailable, isTrue);

        // Should increment totalDestroys even when pendingAdProtection
        expect(result.newState.playerData.stats.totalDestroys, equals(1));
      });
    });

    group('mastery discount', () {
      test('applies mastery level discount to cost', () {
        final random = FakeRandomProvider(0.1); // Success
        final state = createTestState(
          level: 0,
          gold: 100,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 100,
            mastery: MasteryData(level: 4), // 10% discount
          ),
        );
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final command = EnhanceCommand();

        final result = command.execute(state, context);

        // Base cost 5, with 10% discount = 4.5 -> floor = 4
        expect(result.newState.playerData.gold, equals(96)); // 100 - 4

        final goldEvent = result.events.whereType<GoldChangeEvent>().first;
        expect(goldEvent.amount, equals(-4));
      });
    });
  });
}
