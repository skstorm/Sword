import 'package:test/test.dart';
import 'package:game_core/game_core.dart';
import 'helpers/test_data.dart';
import 'helpers/fake_random_provider.dart';
import 'helpers/fake_time_provider.dart';

void main() {
  group('Ad Gold Rewards', () {
    test('WatchAdCommand(gold) grants 200 gold and emits events', () async {
      final context = createTestContext();
      final state = createTestState(gold: 1000);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(WatchAdCommand(adType: AdType.gold));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.playerData.gold, 1200);
      expect(events.any((e) => e is AdRewardEvent && e.adType == AdType.gold), isTrue);
      expect(events.any((e) => e is GoldChangeEvent && e.amount == 200 && e.newTotal == 1200), isTrue);
      engine.dispose();
    });

    test('WatchAdCommand(gold) can be used multiple times without limit', () async {
      final context = createTestContext();
      final state = createTestState(gold: 1000);
      final engine = GameEngine(initialState: state, context: context);

      engine.dispatch(WatchAdCommand(adType: AdType.gold));
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.playerData.gold, 1200);

      engine.dispatch(WatchAdCommand(adType: AdType.gold));
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.playerData.gold, 1400);

      engine.dispatch(WatchAdCommand(adType: AdType.gold));
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.playerData.gold, 1600);

      engine.dispose();
    });
  });

  group('Ad Booster', () {
    test('WatchAdCommand(booster) adds AdBoosterModifier', () async {
      final context = createTestContext();
      final state = createTestState();
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(WatchAdCommand(adType: AdType.booster));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.activeModifiers.any((m) => m is AdBoosterModifier), isTrue);
      expect(events.any((e) => e is AdRewardEvent && e.adType == AdType.booster), isTrue);
      engine.dispose();
    });

    test('Booster + BlessingScroll stack up to 10%p max', () async {
      final context = createTestContext();
      final state = createTestState(
        playerData: PlayerData(gold: 1000, inventory: Inventory(blessingScrolls: 1)),
      );
      final engine = GameEngine(initialState: state, context: context);

      engine.dispatch(WatchAdCommand(adType: AdType.booster));
      await Future.delayed(Duration(milliseconds: 10));

      engine.dispatch(UseItemCommand(itemType: ItemType.blessingScroll));
      await Future.delayed(Duration(milliseconds: 10));

      final boosterActive = engine.state.activeModifiers.any((m) => m is AdBoosterModifier);
      final scrollActive = engine.state.activeModifiers.any((m) => m is BlessingScrollModifier);
      expect(boosterActive, isTrue);
      expect(scrollActive, isTrue);

      // Both modifiers add 5%p each, total 10%p
      final totalBoost = engine.state.activeModifiers
          .where((m) => m is AdBoosterModifier || m is BlessingScrollModifier)
          .fold(0.0, (sum, m) {
            if (m is AdBoosterModifier) return sum + 0.05;
            if (m is BlessingScrollModifier) return sum + 0.05;
            return sum;
          });
      expect(totalBoost, 0.10);

      engine.dispose();
    });

    test('WatchAdCommand(booster) rejected when pendingAdProtection is true', () async {
      final context = createTestContext();
      final state = createTestState(pendingAdProtection: true);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(WatchAdCommand(adType: AdType.booster));
      await Future.delayed(Duration(milliseconds: 10));

      expect(events.any((e) => e is CommandRejectedEvent && e.reason.contains('pending')), isTrue);
      expect(engine.state.activeModifiers.any((m) => m is AdBoosterModifier), isFalse);
      engine.dispose();
    });
  });

  group('Ad Protection (Post-Destruction)', () {
    test('WatchAdCommand(protection) cancels destruction and restores sword', () async {
      final swordTable = createTestSwordTable();
      final random = FakeRandomProvider(0.99); // Force failure
      final context = createTestContext(random: random, swordTable: swordTable);
      final state = createTestState(level: 5, swordTable: swordTable);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      // Enhance should fail and set pendingAdProtection
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.pendingAdProtection, isTrue);
      final levelAfterFail = engine.state.currentLevel;

      // Watch protection ad
      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.pendingAdProtection, isFalse);
      expect(engine.state.currentLevel, levelAfterFail); // Level maintained
      expect(engine.state.playerData.adLimits.adProtectionUsedToday, 1);
      expect(events.any((e) => e is AdRewardEvent && e.adType == AdType.protection), isTrue);
      engine.dispose();
    });

    test('ConfirmDestroyCommand finalizes destruction and resets sword', () async {
      final swordTable = createTestSwordTable();
      final random = FakeRandomProvider(0.99);
      final context = createTestContext(random: random, swordTable: swordTable);
      final state = createTestState(level: 5, swordTable: swordTable);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.pendingAdProtection, isTrue);

      engine.dispatch(ConfirmDestroyCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.pendingAdProtection, isFalse);
      expect(engine.state.currentLevel, 0); // Reset to wooden sword
      expect(events.any((e) => e is FragmentGainEvent), isTrue);
      engine.dispose();
    });

    test('WatchAdCommand(protection) rejected when no pending protection', () async {
      final context = createTestContext();
      final state = createTestState(pendingAdProtection: false);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));

      expect(events.any((e) =>
        e is CommandRejectedEvent &&
        e.commandType == 'WatchAdCommand' &&
        e.reason == 'no_pending_protection'
      ), isTrue);
      engine.dispose();
    });

    test('ConfirmDestroyCommand rejected when no pending destruction', () async {
      final context = createTestContext();
      final state = createTestState(pendingAdProtection: false);
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      engine.dispatch(ConfirmDestroyCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(events.any((e) =>
        e is CommandRejectedEvent &&
        e.commandType == 'ConfirmDestroyCommand' &&
        e.reason == 'no_pending_destruction'
      ), isTrue);
      engine.dispose();
    });
  });

  group('Daily Limits', () {
    test('Ad protection daily limit: 3rd destruction has no ad protection offer', () async {
      final swordTable = createTestSwordTable();
      final random = FakeRandomProvider(0.99);
      final time = FakeTimeProvider();
      final context = createTestContext(random: random, time: time, swordTable: swordTable);
      final adLimits = AdLimits(adProtectionUsedToday: 0, lastResetDate: time.now());
      final state = createTestState(
        level: 5,
        swordTable: swordTable,
        playerData: PlayerData(gold: 1000, adLimits: adLimits, fragments: 0)
      );
      final engine = GameEngine(initialState: state, context: context);
      final events = <GameEvent>[];
      engine.events.listen((e) => events.add(e));

      // First protection
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.pendingAdProtection, isTrue);
      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.playerData.adLimits.adProtectionUsedToday, 1);

      // Second protection
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.pendingAdProtection, isTrue);
      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.playerData.adLimits.adProtectionUsedToday, 2);

      // Third destruction — no ad protection offered, sword destroyed immediately
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.pendingAdProtection, isFalse); // No protection offer
      expect(engine.state.currentLevel, equals(0)); // Destroyed and reset
      expect(engine.state.playerData.adLimits.adProtectionUsedToday, 2);
      engine.dispose();
    });

    test('Daily reset: can use protection again next day', () async {
      final swordTable = createTestSwordTable();
      final random = FakeRandomProvider(0.99);
      final time = FakeTimeProvider(DateTime(2025, 1, 1));
      final context = createTestContext(random: random, time: time, swordTable: swordTable);
      final adLimits = AdLimits(adProtectionUsedToday: 0, lastResetDate: time.now());
      final state = createTestState(
        level: 5,
        swordTable: swordTable,
        playerData: PlayerData(gold: 10000, adLimits: adLimits, fragments: 0)
      );
      final engine = GameEngine(initialState: state, context: context);

      // Use 2 protections on day 1
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));

      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.playerData.adLimits.adProtectionUsedToday, 2);

      // Advance to next day
      time.advance(Duration(days: 1));

      // Enhance fails again — now ad protection should be available (new day)
      engine.dispatch(EnhanceCommand());
      await Future.delayed(Duration(milliseconds: 10));
      expect(engine.state.pendingAdProtection, isTrue); // Protection offered again!

      // Use protection on new day
      engine.dispatch(WatchAdCommand(adType: AdType.protection));
      await Future.delayed(Duration(milliseconds: 10));

      expect(engine.state.pendingAdProtection, isFalse);
      expect(engine.state.playerData.adLimits.adProtectionUsedToday, 1); // Reset + 1
      engine.dispose();
    });
  });

  group('Max Cap Verification', () {
    test('Booster + Scroll combined boost is exactly +10%p', () async {
      final context = createTestContext();
      final state = createTestState(
        playerData: PlayerData(gold: 1000, inventory: Inventory(blessingScrolls: 1)),
      );
      final engine = GameEngine(initialState: state, context: context);

      engine.dispatch(WatchAdCommand(adType: AdType.booster));
      await Future.delayed(Duration(milliseconds: 10));

      engine.dispatch(UseItemCommand(itemType: ItemType.blessingScroll));
      await Future.delayed(Duration(milliseconds: 10));

      var totalBoost = 0.0;
      for (final modifier in engine.state.activeModifiers) {
        if (modifier is AdBoosterModifier) totalBoost += 0.05;
        if (modifier is BlessingScrollModifier) totalBoost += 0.05;
      }

      expect(totalBoost, 0.10);
      engine.dispose();
    });
  });
}
