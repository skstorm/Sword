import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';

// Import logic classes directly (not exported)
import 'package:game_core/logic/economy_logic.dart';

void main() {
  group('EconomyLogic', () {
    late EconomyLogic logic;

    setUp(() {
      logic = EconomyLogic();
    });

    group('canAfford', () {
      test('returns true when player has enough gold', () {
        final state = createTestState(gold: 100);

        expect(logic.canAfford(state, 50), isTrue);
        expect(logic.canAfford(state, 100), isTrue);
      });

      test('returns false when player does not have enough gold', () {
        final state = createTestState(gold: 50);

        expect(logic.canAfford(state, 100), isFalse);
      });

      test('returns false when cost equals gold + 1', () {
        final state = createTestState(gold: 100);

        expect(logic.canAfford(state, 101), isFalse);
      });
    });

    group('spendGold', () {
      test('decreases gold by cost amount', () {
        final state = createTestState(gold: 100);

        final result = logic.spendGold(state, 30);

        expect(result.newState.playerData.gold, equals(70));
      });

      test('emits GoldChangeEvent with negative amount', () {
        final state = createTestState(gold: 100);

        final result = logic.spendGold(state, 30);

        expect(result.events.length, equals(1));
        final event = result.events[0] as GoldChangeEvent;
        expect(event.amount, equals(-30));
        expect(event.newTotal, equals(70));
        expect(event.reason, equals('enhance'));
      });

      test('allows spending all gold', () {
        final state = createTestState(gold: 100);

        final result = logic.spendGold(state, 100);

        expect(result.newState.playerData.gold, equals(0));
        final event = result.events[0] as GoldChangeEvent;
        expect(event.amount, equals(-100));
        expect(event.newTotal, equals(0));
      });
    });

    group('addGold', () {
      test('increases gold by amount', () {
        final state = createTestState(gold: 100);

        final result = logic.addGold(state, 50, 'sell');

        expect(result.newState.playerData.gold, equals(150));
      });

      test('emits GoldChangeEvent with positive amount', () {
        final state = createTestState(gold: 100);

        final result = logic.addGold(state, 50, 'sell');

        expect(result.events.length, equals(1));
        final event = result.events[0] as GoldChangeEvent;
        expect(event.amount, equals(50));
        expect(event.newTotal, equals(150));
        expect(event.reason, equals('sell'));
      });

      test('preserves reason parameter in event', () {
        final state = createTestState(gold: 100);

        final result = logic.addGold(state, 25, 'ad_gold');

        final event = result.events[0] as GoldChangeEvent;
        expect(event.reason, equals('ad_gold'));
      });

      test('adds gold to zero balance', () {
        final state = createTestState(gold: 0);

        final result = logic.addGold(state, 100, 'reward');

        expect(result.newState.playerData.gold, equals(100));
      });
    });
  });
}
