import 'dart:async';
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';

void main() {
  group('Integration Tests - GameEngine', () {
    late GameEngine engine;
    late SwordDataTable swordTable;
    late MasteryLevelTable masteryTable;
    late FakeRandomProvider random;
    late StreamController<GameEvent> eventCapture;
    late List<GameEvent> capturedEvents;

    setUp(() {
      swordTable = createTestSwordTable();
      masteryTable = createTestMasteryTable();
      random = FakeRandomProvider();
      capturedEvents = [];
      eventCapture = StreamController<GameEvent>();
    });

    tearDown(() {
      engine.dispose();
      eventCapture.close();
    });

    test('EnhanceCommand success flows through engine correctly', () async {
      random.setNext(0.1); // Success (< 0.95)
      final initialState = createTestState(
        level: 0,
        gold: 100,
        swordTable: swordTable,
      );
      final context = createTestContext(
        random: random,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      // Capture events
      engine.events.listen((event) => capturedEvents.add(event));

      // Execute enhance command
      engine.dispatch(EnhanceCommand());

      // Wait for events to propagate
      await Future.delayed(Duration(milliseconds: 10));

      // Verify events
      expect(capturedEvents.length, equals(2));
      expect(capturedEvents[0], isA<GoldChangeEvent>());
      expect(capturedEvents[1], isA<EnhanceSuccessEvent>());

      final goldEvent = capturedEvents[0] as GoldChangeEvent;
      expect(goldEvent.amount, equals(-5));
      expect(goldEvent.newTotal, equals(95));

      final successEvent = capturedEvents[1] as EnhanceSuccessEvent;
      expect(successEvent.prevLevel, equals(0));
      expect(successEvent.newLevel, equals(1));
      expect(successEvent.newSwordName, equals('철검'));

      // Verify state
      expect(engine.state.currentLevel, equals(1));
      expect(engine.state.playerData.gold, equals(95));
    });

    test('EnhanceCommand fail flows through engine correctly', () async {
      random.setNext(0.96); // Fail (>= 0.95)
      final initialState = createTestState(
        level: 5,
        gold: 100,
        swordTable: swordTable,
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

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      engine.events.listen((event) => capturedEvents.add(event));

      engine.dispatch(EnhanceCommand());

      await Future.delayed(Duration(milliseconds: 10));

      // Verify events
      expect(capturedEvents.length, equals(2));
      expect(capturedEvents[0], isA<GoldChangeEvent>());
      expect(capturedEvents[1], isA<EnhanceFailEvent>());

      final goldEvent = capturedEvents[0] as GoldChangeEvent;
      expect(goldEvent.amount, isNegative);

      final failEvent = capturedEvents[1] as EnhanceFailEvent;
      expect(failEvent.destroyedLevel, equals(5));
      expect(failEvent.destroyedSwordName, equals('황금검'));
      expect(failEvent.destroyed, isTrue);

      // Verify state reset to wooden sword (no ad protection available)
      expect(engine.state.currentLevel, equals(0));
      expect(engine.state.currentSword.name, equals('나무검'));
    });

    test('SellCommand flows through engine correctly', () async {
      final initialState = createTestState(
        level: 5,
        gold: 100,
        swordTable: swordTable,
      );
      final context = createTestContext(
        swordTable: swordTable,
        masteryTable: masteryTable,
      );

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      engine.events.listen((event) => capturedEvents.add(event));

      engine.dispatch(SellCommand());

      await Future.delayed(Duration(milliseconds: 10));

      // Verify events
      expect(capturedEvents.length, equals(2));
      expect(capturedEvents[0], isA<GoldChangeEvent>());
      expect(capturedEvents[1], isA<SellEvent>());

      final goldEvent = capturedEvents[0] as GoldChangeEvent;
      expect(goldEvent.amount, equals(60)); // 황금검 sell price
      expect(goldEvent.newTotal, equals(160));
      expect(goldEvent.reason, equals('sell'));

      final sellEvent = capturedEvents[1] as SellEvent;
      expect(sellEvent.soldLevel, equals(5));
      expect(sellEvent.soldSwordName, equals('황금검'));
      expect(sellEvent.goldGained, equals(60));

      // Verify state reset to wooden sword
      expect(engine.state.currentLevel, equals(0));
      expect(engine.state.currentSword.name, equals('나무검'));
      expect(engine.state.playerData.gold, equals(160));
    });

    test('CommandRejectedEvent emitted for insufficient gold', () async {
      final initialState = createTestState(
        level: 0,
        gold: 2, // Not enough for enhance (needs 5)
        swordTable: swordTable,
      );
      final context = createTestContext(
        swordTable: swordTable,
        masteryTable: masteryTable,
      );

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      engine.events.listen((event) => capturedEvents.add(event));

      engine.dispatch(EnhanceCommand());

      await Future.delayed(Duration(milliseconds: 10));

      expect(capturedEvents.length, equals(1));
      expect(capturedEvents[0], isA<CommandRejectedEvent>());

      final rejectedEvent = capturedEvents[0] as CommandRejectedEvent;
      expect(rejectedEvent.reason, equals('insufficient_gold'));
      expect(rejectedEvent.commandType, contains('EnhanceCommand'));

      // State should not change
      expect(engine.state.currentLevel, equals(0));
      expect(engine.state.playerData.gold, equals(2));
    });

    test('CommandRejectedEvent emitted for pending ad protection', () async {
      final initialState = createTestState(
        level: 5,
        gold: 100,
        swordTable: swordTable,
        pendingAdProtection: true,
      );
      final context = createTestContext(
        swordTable: swordTable,
        masteryTable: masteryTable,
      );

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      engine.events.listen((event) => capturedEvents.add(event));

      engine.dispatch(EnhanceCommand());

      await Future.delayed(Duration(milliseconds: 10));

      expect(capturedEvents.length, equals(1));
      expect(capturedEvents[0], isA<CommandRejectedEvent>());

      final rejectedEvent = capturedEvents[0] as CommandRejectedEvent;
      expect(rejectedEvent.reason, equals('pending_ad_protection'));
    });

    test('Multiple commands in sequence', () async {
      random.setNext(0.1); // Success
      final initialState = createTestState(
        level: 0,
        gold: 1000,
        swordTable: swordTable,
      );
      final context = createTestContext(
        random: random,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      engine.events.listen((event) => capturedEvents.add(event));

      // Enhance to +1
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.currentLevel, equals(1));

      // Enhance to +2
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.currentLevel, equals(2));

      // Sell +2 sword
      engine.dispatch(SellCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.currentLevel, equals(0));

      // Should have 6 events: 2 gold + 2 success + 1 gold + 1 sell
      expect(capturedEvents.length, equals(6));
    });

    test('Engine state persists between dispatches', () async {
      random.setNext(0.1);
      final initialState = createTestState(
        level: 0,
        gold: 100,
        swordTable: swordTable,
      );
      final context = createTestContext(
        random: random,
        swordTable: swordTable,
        masteryTable: masteryTable,
      );

      engine = GameEngine(
        initialState: initialState,
        context: context,
      );

      // First enhance
      engine.dispatch(EnhanceCommand());
      final firstLevelState = engine.state;

      // Second enhance
      engine.dispatch(EnhanceCommand());
      final secondLevelState = engine.state;

      expect(firstLevelState.currentLevel, equals(1));
      expect(secondLevelState.currentLevel, equals(2));
      expect(secondLevelState.playerData.gold, lessThan(firstLevelState.playerData.gold));
    });
  });
}
