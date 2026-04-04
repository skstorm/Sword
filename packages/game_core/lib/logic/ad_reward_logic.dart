import '../commands/command.dart';
import '../events/ad_event.dart';
import '../events/economy_event.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../util/time_provider.dart';

/// 광고 보상 로직 — 순수 함수 모음
class AdRewardLogic {
  /// 광고 보호권 사용 — 파괴 취소, 현재 단계 유지
  LogicResult applyProtection(GameState state, TimeProvider time) {
    final adLimits = _resetIfNewDay(state.playerData.adLimits, time);
    final newAdLimits = adLimits.copyWith(
      adProtectionUsedToday: adLimits.adProtectionUsedToday + 1,
    );

    final newState = state.copyWith(
      pendingAdProtection: false,
      playerData: state.playerData.copyWith(adLimits: newAdLimits),
    );

    return LogicResult(newState, [
      const AdRewardEvent(adType: AdType.protection, rewardDetail: 'sword_saved'),
    ]);
  }

  /// 광고 골드 보상 — 200골드 지급
  LogicResult giveGold(GameState state) {
    const goldAmount = 200;
    final newGold = state.playerData.gold + goldAmount;
    final newState = state.copyWith(
      playerData: state.playerData.copyWith(gold: newGold),
    );

    return LogicResult(newState, [
      const AdRewardEvent(adType: AdType.gold, rewardDetail: '200'),
      GoldChangeEvent(amount: goldAmount, newTotal: newGold, reason: 'ad_gold'),
    ]);
  }

  /// 광고 부스터 — 확률 +5%p (activeModifiers에 추가)
  LogicResult applyBooster(GameState state) {
    final newState = state.copyWith(
      activeModifiers: [...state.activeModifiers, AdBoosterModifier()],
    );

    return LogicResult(newState, [
      const AdRewardEvent(adType: AdType.booster, rewardDetail: '+5%p'),
    ]);
  }

  /// 보호권 사용 가능 여부 (일일 2회 제한)
  bool canUseProtection(GameState state, TimeProvider time) {
    final adLimits = _resetIfNewDay(state.playerData.adLimits, time);
    return adLimits.adProtectionUsedToday < 2;
  }

  /// 날짜 변경 시 일일 카운터 리셋
  AdLimits _resetIfNewDay(AdLimits adLimits, TimeProvider time) {
    final now = time.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      adLimits.lastResetDate.year,
      adLimits.lastResetDate.month,
      adLimits.lastResetDate.day,
    );

    if (today.isAfter(lastReset)) {
      return AdLimits(adProtectionUsedToday: 0, lastResetDate: today);
    }
    return adLimits;
  }
}
