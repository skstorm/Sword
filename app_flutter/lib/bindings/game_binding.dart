import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:game_core/game_core.dart';
import '../animations/enhance_animation_controller.dart';
import '../animations/enhance_animation_config.dart';
import '../animations/basic_enhance_animation.dart';
import '../repositories/in_memory_repository.dart';

// Data providers
final swordTableProvider = FutureProvider<SwordDataTable>((ref) async {
  final csv = await rootBundle.loadString('assets/data/swords.csv');
  return SwordDataTable(SwordDataLoader().parse(csv));
});

final masteryTableProvider = FutureProvider<MasteryLevelTable>((ref) async {
  final csv = await rootBundle.loadString('assets/data/mastery_levels.csv');
  return MasteryLevelTable(MasteryDataLoader().parse(csv));
});

// Storage repository provider — P1: InMemory, P2: Hive/Synced로 교체
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return InMemoryRepository();
});

// Game engine provider - depends on data loading
final gameEngineProvider = FutureProvider<GameEngine>((ref) async {
  final swordTable = await ref.watch(swordTableProvider.future);
  final masteryTable = await ref.watch(masteryTableProvider.future);
  final repository = ref.watch(storageRepositoryProvider);

  final context = GameContext(
    random: SeededRandomProvider(DateTime.now().millisecondsSinceEpoch),
    time: RealTimeProvider(),
    swordTable: swordTable,
    masteryTable: masteryTable,
  );

  final playerData = await repository.load();
  final initialState = _createInitialState(playerData, swordTable);

  return GameEngine(initialState: initialState, context: context);
});

// Current state provider - rebuilds when engine state changes
final gameStateProvider = StateProvider<GameState?>((ref) => null);

// Animation providers
final enhanceAnimationProvider = Provider<EnhanceAnimationController>((ref) {
  return BasicEnhanceAnimation();
});

final animationConfigProvider = Provider<EnhanceAnimationConfigTable>((ref) {
  return EnhanceAnimationConfigTable.fromDefaults();
});

// Helper function to create initial state (mirrors GameSessionLogic.createInitialState)
GameState _createInitialState(PlayerData playerData, SwordDataTable swordTable) {
  final woodenSword = swordTable.getSword(0)!;

  // First run: give initial gold
  final updatedPlayerData = playerData.isFirstRun
      ? playerData.copyWith(gold: 200, isFirstRun: false)
      : playerData;

  return GameState(
    currentSword: woodenSword,
    currentLevel: 0,
    playerData: updatedPlayerData,
    activeModifiers: [],
    hasActiveProtection: false,
    pendingAdProtection: false,
  );
}

// Random provider implementation
class SeededRandomProvider implements RandomProvider {
  final Random _random;
  SeededRandomProvider(int seed) : _random = Random(seed);

  @override
  double nextDouble() => _random.nextDouble();
}

// Time provider implementation
class RealTimeProvider implements TimeProvider {
  @override
  DateTime now() => DateTime.now();
}
