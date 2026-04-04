import '../models/game_state.dart';
import '../models/player.dart';
import '../models/sword.dart';

/// 게임 세션 로직 — 순수 함수 모음
class GameSessionLogic {
  const GameSessionLogic();
  /// 초기 게임 상태 생성
  GameState createInitialState(
    PlayerData playerData,
    SwordDataTable swordTable,
  ) {
    final woodenSword = swordTable.getSword(0)!;

    // 첫 실행 시 초기 골드 지급
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

  /// 나무 검으로 리셋
  GameState resetToWoodenSword(
    GameState state,
    SwordDataTable swordTable,
  ) {
    final woodenSword = swordTable.getSword(0)!;

    return state.copyWith(
      currentSword: woodenSword,
      currentLevel: 0,
      activeModifiers: [],
      hasActiveProtection: false,
      pendingAdProtection: false,
    );
  }
}
