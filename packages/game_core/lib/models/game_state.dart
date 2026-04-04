import 'modifier.dart';
import 'sword.dart';
import 'player.dart';

export 'modifier.dart';

/// 세션 중 변하는 상태를 통합. 커맨드의 입력이자 출력.
class GameState {
  final Sword currentSword;
  final int currentLevel;
  final PlayerData playerData;
  final List<Modifier> activeModifiers;
  final bool hasActiveProtection;
  final bool pendingAdProtection;

  const GameState({
    required this.currentSword,
    required this.currentLevel,
    required this.playerData,
    this.activeModifiers = const [],
    this.hasActiveProtection = false,
    this.pendingAdProtection = false,
  });

  GameState copyWith({
    Sword? currentSword,
    int? currentLevel,
    PlayerData? playerData,
    List<Modifier>? activeModifiers,
    bool? hasActiveProtection,
    bool? pendingAdProtection,
  }) {
    return GameState(
      currentSword: currentSword ?? this.currentSword,
      currentLevel: currentLevel ?? this.currentLevel,
      playerData: playerData ?? this.playerData,
      activeModifiers: activeModifiers ?? this.activeModifiers,
      hasActiveProtection: hasActiveProtection ?? this.hasActiveProtection,
      pendingAdProtection: pendingAdProtection ?? this.pendingAdProtection,
    );
  }
}
