import 'dart:math';
import 'command.dart';
import '../events/game_event.dart';
import '../events/enhance_event.dart';
import '../logic/enhance_logic.dart';
import '../logic/economy_logic.dart';
import '../logic/ad_reward_logic.dart';
import '../logic/fragment_logic.dart';
import '../logic/mastery_logic.dart';
import '../logic/game_session_logic.dart';
import '../models/game_state.dart';

/// 강화 커맨드
class EnhanceCommand extends Command {
  const EnhanceCommand({super.timestamp});

  /// 숙련도 할인을 적용한 강화 비용 계산
  static int calculateCost(GameState state, GameContext context) {
    final targetSword = context.swordTable.getSword(state.currentLevel + 1);
    if (targetSword == null) return 0;
    final baseCost = targetSword.enhanceCost;
    final discount = context.masteryTable
        .getLevel(state.playerData.mastery.level)
        .costDiscount;
    return (baseCost * (1 - discount)).floor();
  }

  @override
  String? validate(GameState state, GameContext context) {
    if (state.pendingAdProtection) return 'pending_ad_protection';

    final targetSword = context.swordTable.getSword(state.currentLevel + 1);
    if (targetSword == null) return 'max_level_reached';

    final cost = calculateCost(state, context);
    if (!const EconomyLogic().canAfford(state, cost)) {
      return 'insufficient_gold';
    }

    return null;
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final events = <GameEvent>[];

    // 1. 비용 계산 및 골드 차감
    final targetSword = context.swordTable.getSword(state.currentLevel + 1)!;
    final cost = calculateCost(state, context);

    final economyResult = const EconomyLogic().spendGold(state, cost);
    var currentState = economyResult.newState;
    events.addAll(economyResult.events);

    // 2. 강화 시도
    const enhanceLogic = EnhanceLogic();
    final effectiveRate = enhanceLogic.getEffectiveRate(currentState, targetSword);
    final success = enhanceLogic.roll(effectiveRate, context.random);

    if (success) {
      final successResult = enhanceLogic.handleSuccess(
        currentState, targetSword, context.swordTable,
      );
      currentState = successResult.newState;
      events.addAll(successResult.events);

      // 통계 업데이트 — 성공
      currentState = _updateStatsOnSuccess(currentState);
    } else {
      // 광고 보호 가능 여부를 AdRewardLogic에 위임 (단일 책임)
      final adAvailable = const AdRewardLogic().canUseProtection(
        currentState, context.time,
      );

      final failResult = enhanceLogic.handleFail(
        currentState, context.swordTable,
        adProtectionAvailable: adAvailable,
      );
      currentState = failResult.newState;
      events.addAll(failResult.events);

      final failEvent = failResult.events.whereType<EnhanceFailEvent>().first;
      final destroyed = failEvent.destroyed;

      // 파괴 확정 처리 (실제 파괴 + 광고 보호 대기가 아닌 경우)
      if (destroyed && !currentState.pendingAdProtection) {
        final fragBonus = context.masteryTable
            .getLevel(currentState.playerData.mastery.level)
            .fragmentBonus;
        final fragResult = const FragmentLogic().giveFragments(
          currentState, fragBonus,
        );
        currentState = fragResult.newState;
        events.addAll(fragResult.events);

        currentState = const GameSessionLogic().resetToWoodenSword(
          currentState, context.swordTable,
        );
      }

      // 통계 업데이트 — 실패
      currentState = _updateStatsOnFail(currentState, destroyed);
    }

    // 장인 숙련도 경험치 +1 (성공/실패 무관)
    final masteryResult = const MasteryLogic().addExp(
      currentState, context.masteryTable,
    );
    currentState = masteryResult.newState;
    events.addAll(masteryResult.events);

    return CommandResult(newState: currentState, events: events);
  }

  /// 성공 시 통계 갱신
  static GameState _updateStatsOnSuccess(GameState state) {
    final stats = state.playerData.stats;
    final newLevel = state.currentLevel;
    return state.copyWith(
      playerData: state.playerData.copyWith(
        stats: stats.copyWith(
          highestEnhanceLevel: max(stats.highestEnhanceLevel, newLevel),
          weeklyHighestLevel: max(stats.weeklyHighestLevel, newLevel),
          totalEnhanceAttempts: stats.totalEnhanceAttempts + 1,
          currentConsecutiveSuccess: stats.currentConsecutiveSuccess + 1,
          maxConsecutiveSuccess: max(
            stats.maxConsecutiveSuccess,
            stats.currentConsecutiveSuccess + 1,
          ),
          currentConsecutiveFail: 0,
        ),
      ),
    );
  }

  /// 실패 시 통계 갱신
  static GameState _updateStatsOnFail(GameState state, bool destroyed) {
    final stats = state.playerData.stats;
    return state.copyWith(
      playerData: state.playerData.copyWith(
        stats: stats.copyWith(
          totalDestroys: destroyed ? stats.totalDestroys + 1 : stats.totalDestroys,
          totalEnhanceAttempts: stats.totalEnhanceAttempts + 1,
          currentConsecutiveFail: stats.currentConsecutiveFail + 1,
          maxConsecutiveFail: max(
            stats.maxConsecutiveFail,
            stats.currentConsecutiveFail + 1,
          ),
          currentConsecutiveSuccess: 0,
        ),
      ),
    );
  }
}
