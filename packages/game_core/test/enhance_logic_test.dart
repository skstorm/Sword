import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';

// Import logic classes directly (not exported)
import 'package:game_core/logic/enhance_logic.dart';

void main() {
  group('EnhanceLogic', () {
    late EnhanceLogic logic;
    late SwordDataTable swordTable;

    setUp(() {
      logic = EnhanceLogic();
      swordTable = createTestSwordTable();
    });

    group('getEffectiveRate', () {
      test('returns base success rate when no modifiers', () {
        final state = createTestState(level: 0, swordTable: swordTable);
        final targetSword = swordTable.getSword(1)!; // +1 철검, 95%

        final effectiveRate = logic.getEffectiveRate(state, targetSword);

        expect(effectiveRate, closeTo(0.95, 0.001));
      });

      test('applies modifiers to base rate', () {
        // Create a test modifier that adds 0.05
        final modifier = _TestModifier(0.05);
        final state = createTestState(
          level: 0,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );
        final targetSword = swordTable.getSword(1)!; // 95%

        final effectiveRate = logic.getEffectiveRate(state, targetSword);

        // 0.95 + 0.05 = 1.0
        expect(effectiveRate, closeTo(1.0, 0.001));
      });

      test('clamps effective rate to 0.0 minimum', () {
        final modifier = _TestModifier(-2.0); // Subtract 2.0
        final state = createTestState(
          level: 0,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );
        final targetSword = swordTable.getSword(1)!;

        final effectiveRate = logic.getEffectiveRate(state, targetSword);

        expect(effectiveRate, equals(0.0));
      });

      test('clamps effective rate to 1.0 maximum', () {
        final modifier = _TestModifier(0.5); // Add 0.5
        final state = createTestState(
          level: 0,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );
        final targetSword = swordTable.getSword(1)!; // 0.95 + 0.5 = 1.45

        final effectiveRate = logic.getEffectiveRate(state, targetSword);

        expect(effectiveRate, equals(1.0));
      });
    });

    group('roll', () {
      test('returns true when random < successRate', () {
        final random = FakeRandomProvider(0.5);
        final result = logic.roll(0.6, random); // 0.5 < 0.6

        expect(result, isTrue);
      });

      test('returns false when random >= successRate', () {
        final random = FakeRandomProvider(0.7);
        final result = logic.roll(0.6, random); // 0.7 >= 0.6

        expect(result, isFalse);
      });

      test('returns false when random equals successRate', () {
        final random = FakeRandomProvider(0.5);
        final result = logic.roll(0.5, random); // 0.5 == 0.5

        expect(result, isFalse);
      });
    });

    group('handleSuccess', () {
      test('upgrades to next level sword', () {
        final state = createTestState(level: 0, swordTable: swordTable);
        final newSword = swordTable.getSword(1)!;

        final result = logic.handleSuccess(state, newSword, swordTable);

        expect(result.newState.currentLevel, equals(1));
        expect(result.newState.currentSword.name, equals('철검'));
      });

      test('clears active modifiers after success', () {
        final modifier = _TestModifier(0.1);
        final state = createTestState(
          level: 0,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );
        final newSword = swordTable.getSword(1)!;

        final result = logic.handleSuccess(state, newSword, swordTable);

        expect(result.newState.activeModifiers, isEmpty);
      });

      test('emits EnhanceSuccessEvent with correct data', () {
        final state = createTestState(level: 0, swordTable: swordTable);
        final newSword = swordTable.getSword(1)!;

        final result = logic.handleSuccess(state, newSword, swordTable);

        expect(result.events.length, equals(1));
        final event = result.events[0] as EnhanceSuccessEvent;
        expect(event.prevLevel, equals(0));
        expect(event.newLevel, equals(1));
        expect(event.newSwordName, equals('철검'));
        expect(event.goldSpent, equals(5));
      });
    });

    group('handleFail', () {
      test('destroys sword when no active protection', () {
        final state = createTestState(
          level: 5,
          swordTable: swordTable,
          hasActiveProtection: false,
        );

        final result = logic.handleFail(
          state, swordTable, adProtectionAvailable: true,
        );

        expect(result.events.length, equals(1));
        final event = result.events[0] as EnhanceFailEvent;
        expect(event.destroyed, isTrue);
        expect(event.destroyedLevel, equals(5));
        expect(event.destroyedSwordName, equals('황금검'));
      });

      test('blocks destruction when hasActiveProtection is true', () {
        final state = createTestState(
          level: 5,
          swordTable: swordTable,
          hasActiveProtection: true,
        );

        final result = logic.handleFail(
          state, swordTable, adProtectionAvailable: false,
        );

        final event = result.events[0] as EnhanceFailEvent;
        expect(event.destroyed, isFalse);
        expect(result.newState.hasActiveProtection, isFalse); // Protection consumed
      });

      test('does not add fragments directly (fragments handled by FragmentLogic)', () {
        final state = createTestState(
          level: 5,
          swordTable: swordTable,
          playerData: PlayerData(gold: 1000, fragments: 10),
        );

        final result = logic.handleFail(
          state, swordTable, adProtectionAvailable: false,
        );

        // enhance_logic no longer adds fragments directly — FragmentLogic handles it
        expect(result.newState.playerData.fragments, equals(10));
        final event = result.events[0] as EnhanceFailEvent;
        expect(event.fragmentsGained, equals(swordTable.getSword(5)!.fragmentReward));
      });

      test('clears active modifiers after fail', () {
        final modifier = _TestModifier(0.1);
        final state = createTestState(
          level: 5,
          swordTable: swordTable,
          activeModifiers: [modifier],
        );

        final result = logic.handleFail(
          state, swordTable, adProtectionAvailable: false,
        );

        expect(result.newState.activeModifiers, isEmpty);
      });

      test('sets pendingAdProtection when ad protection available', () {
        final state = createTestState(
          level: 5,
          swordTable: swordTable,
          playerData: PlayerData(gold: 1000),
        );

        final result = logic.handleFail(
          state, swordTable, adProtectionAvailable: true,
        );

        expect(result.newState.pendingAdProtection, isTrue);
        final event = result.events[0] as EnhanceFailEvent;
        expect(event.adProtectionAvailable, isTrue);
      });

      test('does not set pendingAdProtection when ad protection unavailable', () {
        final state = createTestState(
          level: 5,
          swordTable: swordTable,
          playerData: PlayerData(gold: 1000),
        );

        final result = logic.handleFail(
          state, swordTable, adProtectionAvailable: false,
        );

        expect(result.newState.pendingAdProtection, isFalse);
        final event = result.events[0] as EnhanceFailEvent;
        expect(event.adProtectionAvailable, isFalse);
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
