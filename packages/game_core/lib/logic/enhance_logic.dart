import '../commands/command.dart';
import '../events/enhance_event.dart';
import '../models/game_state.dart';
import '../models/sword.dart';
import '../util/random_provider.dart';

/// 강화 로직 — 순수 함수 모음
class EnhanceLogic {
  /// 현재 상태의 수정자를 적용한 실효 성공률 반환 (0.0~1.0)
  double getEffectiveRate(GameState state, Sword targetSword) {
    double rate = targetSword.successRate ?? 0.0;
    for (final modifier in state.activeModifiers) {
      rate = modifier.apply(rate);
    }
    return rate.clamp(0.0, 1.0);
  }

  /// 확률 롤 — 성공 여부 판정
  bool roll(double effectiveRate, RandomProvider random) {
    return random.nextDouble() < effectiveRate;
  }

  /// 강화 성공 처리
  LogicResult handleSuccess(
    GameState state,
    Sword newSword,
    SwordDataTable table,
  ) {
    final newState = state.copyWith(
      currentSword: newSword,
      currentLevel: state.currentLevel + 1,
      activeModifiers: [],
    );

    final event = EnhanceSuccessEvent(
      prevLevel: state.currentLevel,
      newLevel: state.currentLevel + 1,
      newSwordName: newSword.name,
      goldSpent: newSword.enhanceCost,
    );

    return LogicResult(newState, [event]);
  }

  /// 강화 실패 처리
  LogicResult handleFail(
    GameState state,
    SwordDataTable table,
    GameContext context,
  ) {
    final fragmentsGained = state.currentSword.fragmentReward;
    final goldSpent = table.getSword(state.currentLevel + 1)?.enhanceCost ?? 0;
    final adAvailable = _isAdProtectionAvailable(state, context);

    GameState newState;
    bool destroyed;

    if (state.hasActiveProtection) {
      // 보호 부적이 활성화되어 있으면 파괴 방지 — 파편 없음
      newState = state.copyWith(
        hasActiveProtection: false,
        activeModifiers: [],
      );
      destroyed = false;
    } else {
      // 파괴 처리, 광고 보호 가능 여부 설정
      // 파편 지급은 EnhanceCommand/ConfirmDestroyCommand에서 FragmentLogic을 통해 처리
      newState = state.copyWith(
        pendingAdProtection: adAvailable,
        activeModifiers: [],
      );
      destroyed = true;
    }

    final event = EnhanceFailEvent(
      destroyedLevel: state.currentLevel,
      destroyedSwordName: state.currentSword.name,
      fragmentsGained: destroyed ? fragmentsGained : 0,
      goldSpent: goldSpent,
      adProtectionAvailable: adAvailable,
      destroyed: destroyed,
    );

    return LogicResult(newState, [event]);
  }

  /// 광고 보호 사용 가능 여부 확인 (private)
  bool _isAdProtectionAvailable(GameState state, GameContext context) {
    final now = context.time.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      state.playerData.adLimits.lastResetDate.year,
      state.playerData.adLimits.lastResetDate.month,
      state.playerData.adLimits.lastResetDate.day,
    );
    // 날짜가 바뀌면 카운터 리셋으로 간주
    if (today.isAfter(lastReset)) return true;
    return state.playerData.adLimits.adProtectionUsedToday < 2;
  }
}
