import 'package:test/test.dart';
import 'package:game_core/game_core.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';

void main() {
  group('Collection System', () {
    late SwordDataTable swordTable;
    late MasteryLevelTable masteryTable;

    setUp(() {
      swordTable = createTestSwordTable();
      masteryTable = createTestMasteryTable();
    });

    group('Basic Collection', () {
      test('collect +10 sword emits CollectEvent and resets to wooden', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 10,
          gold: 1000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        // Check event
        final collectEvents = events.whereType<CollectEvent>().toList();
        expect(collectEvents.length, equals(1));
        expect(collectEvents.first.collectedLevel, equals(10));
        expect(collectEvents.first.collectedSwordName, equals('엑스칼리버'));
        expect(collectEvents.first.isNewCollection, isTrue);

        // Check state reset to wooden sword
        expect(engine.state.currentLevel, equals(0));
        expect(engine.state.currentSword.name, equals('나무검'));

        // Check collection data
        expect(engine.state.playerData.collection.collected[10], equals(1));
        engine.dispose();
      });

      test('collect same sword twice - second time isNewCollection is false', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 10,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            collection: CollectionData(collected: {10: 1}),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final collectEvents = events.whereType<CollectEvent>().toList();
        expect(collectEvents.length, equals(1));
        expect(collectEvents.first.isNewCollection, isFalse);
        expect(engine.state.playerData.collection.collected[10], equals(2));
        engine.dispose();
      });

      test('collect +15 sword successfully', () async {
        final random = FakeRandomProvider(0.1);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 15,
          gold: 1000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final collectEvents = events.whereType<CollectEvent>().toList();
        expect(collectEvents.length, equals(1));
        expect(collectEvents.first.collectedLevel, equals(15));
        expect(collectEvents.first.collectedSwordName, equals('참마도'));
        expect(engine.state.currentLevel, equals(0));
        engine.dispose();
      });
    });

    group('Validation', () {
      test('reject collection when level < 10', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 9,
          gold: 1000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final rejectedEvents = events.whereType<CommandRejectedEvent>().toList();
        expect(rejectedEvents.length, equals(1));
        expect(rejectedEvents.first.reason, equals('level_too_low'));
        expect(engine.state.currentLevel, equals(9)); // No change
        engine.dispose();
      });

      test('reject collection when pendingAdProtection is true', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 10,
          gold: 1000,
          swordTable: swordTable,
          pendingAdProtection: true,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final rejectedEvents = events.whereType<CommandRejectedEvent>().toList();
        expect(rejectedEvents.length, equals(1));
        expect(rejectedEvents.first.reason, equals('pending_ad_protection'));
        engine.dispose();
      });

      test('collect level 9 emits rejection', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 9,
          gold: 1000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final rejectedEvents = events.whereType<CommandRejectedEvent>().toList();
        expect(rejectedEvents.length, equals(1));
        expect(rejectedEvents.first.commandType, contains('CollectCommand'));
        expect(rejectedEvents.first.reason, equals('level_too_low'));
        engine.dispose();
      });
    });

    group('Completion Rate', () {
      test('completion rate calculated correctly', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 13,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            collection: CollectionData(collected: {10: 1, 11: 1, 12: 1}),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final collectEvents = events.whereType<CollectEvent>().toList();
        expect(collectEvents.length, equals(1));
        // 4 unique out of 11 total = 4/11 ≈ 0.3636
        expect(collectEvents.first.totalCompletion, closeTo(0.3636, 0.01));
        engine.dispose();
      });

      test('100% completion emits CollectionCompleteEvent', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 20,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            collection: CollectionData(collected: {
              10: 1,
              11: 1,
              12: 1,
              13: 1,
              14: 1,
              15: 1,
              16: 1,
              17: 1,
              18: 1,
              19: 1,
            }),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final collectEvents = events.whereType<CollectEvent>().toList();
        expect(collectEvents.length, equals(1));
        expect(collectEvents.first.totalCompletion, equals(1.0));

        final completeEvents = events.whereType<CollectionCompleteEvent>().toList();
        expect(completeEvents.length, equals(1));
        engine.dispose();
      });

      test('no complete event when not all swords collected', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 15,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            collection: CollectionData(collected: {10: 1, 11: 1, 12: 1}),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final completeEvents = events.whereType<CollectionCompleteEvent>();
        expect(completeEvents.isEmpty, isTrue);
        engine.dispose();
      });
    });

    group('Multiple Collections', () {
      test('multiple unique collections tracked correctly', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 10,
          gold: 1000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.collection.uniqueCount, equals(1));
        expect(engine.state.playerData.collection.collected[10], equals(1));
        engine.dispose();
      });

      test('collect different swords increases unique count', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 11,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            collection: CollectionData(collected: {10: 2}),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.collection.uniqueCount, equals(2));
        expect(engine.state.playerData.collection.collected[10], equals(2));
        expect(engine.state.playerData.collection.collected[11], equals(1));
        engine.dispose();
      });

      test('collect same sword multiple times updates count only', () async {
        final context = createTestContext(
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 10,
          gold: 1000,
          swordTable: swordTable,
          playerData: PlayerData(
            gold: 1000,
            collection: CollectionData(collected: {10: 5}),
          ),
        );
        final engine = GameEngine(initialState: state, context: context);

        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.playerData.collection.uniqueCount, equals(1));
        expect(engine.state.playerData.collection.collected[10], equals(6));
        engine.dispose();
      });
    });

    group('Integration', () {
      test('enhance to +10 then collect successfully', () async {
        final random = FakeRandomProvider(0.01); // Always succeed
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 9,
          gold: 10000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        // Enhance from +9 to +10
        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.currentLevel, equals(10));

        // Now collect
        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final collectEvents = events.whereType<CollectEvent>().toList();
        expect(collectEvents.length, equals(1));
        expect(collectEvents.first.collectedLevel, equals(10));
        expect(engine.state.currentLevel, equals(0));
        engine.dispose();
      });

      test('cannot collect immediately after enhance to +9', () async {
        final random = FakeRandomProvider(0.01);
        final context = createTestContext(
          random: random,
          swordTable: swordTable,
          masteryTable: masteryTable,
        );
        final state = createTestState(
          level: 8,
          gold: 10000,
          swordTable: swordTable,
        );
        final engine = GameEngine(initialState: state, context: context);
        final events = <GameEvent>[];
        engine.events.listen((e) => events.add(e));

        // Enhance from +8 to +9
        engine.dispatch(EnhanceCommand());
        await Future.delayed(Duration(milliseconds: 10));

        expect(engine.state.currentLevel, equals(9));

        // Try to collect - should fail
        engine.dispatch(CollectCommand());
        await Future.delayed(Duration(milliseconds: 10));

        final rejectedEvents = events.whereType<CommandRejectedEvent>().toList();
        expect(rejectedEvents.any((e) => e.reason == 'level_too_low'), isTrue);
        expect(engine.state.currentLevel, equals(9)); // Still at +9
        engine.dispose();
      });
    });
  });
}
