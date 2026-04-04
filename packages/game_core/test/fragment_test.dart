import 'package:test/test.dart';
import 'package:game_core/game_core.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';

void main() {
  late SwordDataTable swordTable;

  setUp(() {
    swordTable = createTestSwordTable();
  });

  group('ExchangeCommand', () {
    test('exchanges fragments for protection amulet', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(gold: 100, fragments: 50),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(ExchangeCommand(itemType: ItemType.protectionAmulet));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.playerData.fragments, equals(20)); // 50 - 30
      expect(engine.state.playerData.inventory.protectionAmulets, equals(1));
      expect(events.whereType<ExchangeEvent>().length, equals(1));
      final event = events.whereType<ExchangeEvent>().first;
      expect(event.fragmentsSpent, equals(30));
      engine.dispose();
    });

    test('exchanges fragments for blessing scroll', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(gold: 100, fragments: 30),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(ExchangeCommand(itemType: ItemType.blessingScroll));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.playerData.fragments, equals(15)); // 30 - 15
      expect(engine.state.playerData.inventory.blessingScrolls, equals(1));
      engine.dispose();
    });

    test('exchanges fragments for gold pouch', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(gold: 100, fragments: 20),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(ExchangeCommand(itemType: ItemType.goldPouch));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.playerData.fragments, equals(10)); // 20 - 10
      expect(engine.state.playerData.gold, equals(600)); // 100 + 500
      expect(events.whereType<GoldChangeEvent>().length, equals(1));
      final goldEvent = events.whereType<GoldChangeEvent>().first;
      expect(goldEvent.amount, equals(500));
      expect(goldEvent.reason, equals('exchange'));
      engine.dispose();
    });

    test('rejects exchange with insufficient fragments', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(gold: 100, fragments: 5),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(ExchangeCommand(itemType: ItemType.protectionAmulet));
      await Future.delayed(Duration(milliseconds: 10));

      expect(events.length, equals(1));
      expect(events[0], isA<CommandRejectedEvent>());
      expect((events[0] as CommandRejectedEvent).reason, equals('insufficient_fragments'));
      engine.dispose();
    });

    test('exchanges multiple quantity', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(gold: 100, fragments: 60),
      );
      final engine = GameEngine(initialState: state, context: context);

      engine.dispatch(ExchangeCommand(itemType: ItemType.protectionAmulet, quantity: 2));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.playerData.fragments, equals(0)); // 60 - 60
      expect(engine.state.playerData.inventory.protectionAmulets, equals(2));
      engine.dispose();
    });
  });

  group('UseItemCommand', () {
    test('uses protection amulet', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(
          gold: 100,
          inventory: Inventory(protectionAmulets: 2),
        ),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(UseItemCommand(itemType: ItemType.protectionAmulet));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.hasActiveProtection, isTrue);
      expect(engine.state.playerData.inventory.protectionAmulets, equals(1));
      expect(events.whereType<UseItemEvent>().length, equals(1));
      final event = events.whereType<UseItemEvent>().first;
      expect(event.itemType, equals(ItemType.protectionAmulet));
      expect(event.remainingCount, equals(1));
      engine.dispose();
    });

    test('uses blessing scroll adds modifier', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(
          gold: 100,
          inventory: Inventory(blessingScrolls: 1),
        ),
      );
      final engine = GameEngine(initialState: state, context: context);

      engine.dispatch(UseItemCommand(itemType: ItemType.blessingScroll));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.activeModifiers.length, equals(1));
      expect(engine.state.activeModifiers[0], isA<BlessingScrollModifier>());
      expect(engine.state.playerData.inventory.blessingScrolls, equals(0));
      engine.dispose();
    });

    test('rejects use with no items', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        playerData: PlayerData(gold: 100, inventory: Inventory()),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(UseItemCommand(itemType: ItemType.protectionAmulet));
      await Future.delayed(Duration(milliseconds: 10));

      expect(events[0], isA<CommandRejectedEvent>());
      expect((events[0] as CommandRejectedEvent).reason, equals('no_item'));
      engine.dispose();
    });

    test('rejects protection amulet when already protected', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(
        swordTable: swordTable,
        hasActiveProtection: true,
        playerData: PlayerData(
          gold: 100,
          inventory: Inventory(protectionAmulets: 1),
        ),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(UseItemCommand(itemType: ItemType.protectionAmulet));
      await Future.delayed(Duration(milliseconds: 10));

      expect(events[0], isA<CommandRejectedEvent>());
      expect((events[0] as CommandRejectedEvent).reason, equals('already_protected'));
      engine.dispose();
    });

    test('rejects gold pouch via UseItemCommand', () async {
      final context = createTestContext(swordTable: swordTable);
      final state = createTestState(swordTable: swordTable);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(UseItemCommand(itemType: ItemType.goldPouch));
      await Future.delayed(Duration(milliseconds: 10));

      expect(events[0], isA<CommandRejectedEvent>());
      expect((events[0] as CommandRejectedEvent).reason, equals('invalid_item_type'));
      engine.dispose();
    });
  });

  group('Protection amulet effect', () {
    test('prevents destruction on enhance fail', () async {
      final random = FakeRandomProvider(0.99); // Will fail
      final context = createTestContext(random: random, swordTable: swordTable);
      final state = createTestState(
        level: 5,
        swordTable: swordTable,
        playerData: PlayerData(
          gold: 1000,
          inventory: Inventory(protectionAmulets: 1),
          adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)),
        ),
      );
      final engine = GameEngine(initialState: state, context: context);

      // Use amulet first
      engine.dispatch(UseItemCommand(itemType: ItemType.protectionAmulet));
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.hasActiveProtection, isTrue);

      // Enhance fails but sword is protected
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.currentLevel, equals(5)); // Level maintained
      expect(engine.state.hasActiveProtection, isFalse); // Protection consumed
      expect(engine.state.playerData.inventory.protectionAmulets, equals(0));
      engine.dispose();
    });
  });

  group('Blessing scroll effect', () {
    test('increases effective rate by 5%p', () async {
      final random = FakeRandomProvider();
      final context = createTestContext(random: random, swordTable: swordTable);
      final state = createTestState(
        level: 5,
        swordTable: swordTable,
        playerData: PlayerData(
          gold: 1000,
          inventory: Inventory(blessingScrolls: 1),
        ),
      );
      final engine = GameEngine(initialState: state, context: context);

      // Use scroll
      engine.dispatch(UseItemCommand(itemType: ItemType.blessingScroll));
      await Future.delayed(Duration(milliseconds: 10));

      // +5→+6 base rate is 70% (0.70), with scroll: 0.75
      // Set random to 0.74 → should succeed with scroll but fail without
      random.setNext(0.74);
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.currentLevel, equals(6)); // Success!
      engine.dispose();
    });
  });

  group('Fragment gain on destroy', () {
    test('gains fragments when sword is destroyed', () async {
      final random = FakeRandomProvider(0.99); // Will fail
      final context = createTestContext(random: random, swordTable: swordTable);
      final state = createTestState(
        level: 5,
        swordTable: swordTable,
        playerData: PlayerData(
          gold: 1000,
          fragments: 0,
          adLimits: AdLimits(adProtectionUsedToday: 2, lastResetDate: DateTime(2025, 1, 1)), // No ad protection
        ),
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));

      // +5 sword gives 1 fragment (from CSV)
      final fragEvents = events.whereType<FragmentGainEvent>();
      expect(fragEvents.length, equals(1));
      expect(fragEvents.first.amount, equals(1)); // fragmentReward=1 + bonus=0
      expect(engine.state.playerData.fragments, equals(1));
      expect(engine.state.currentLevel, equals(0)); // Reset to wooden
      engine.dispose();
    });
  });
}
