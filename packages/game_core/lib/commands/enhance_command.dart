import 'dart:math';
import 'command.dart';
import '../events/game_event.dart';
import '../events/enhance_event.dart';
import '../logic/enhance_logic.dart';
import '../logic/economy_logic.dart';
import '../logic/game_session_logic.dart';
import '../models/game_state.dart';

/// 강화 커맨드
class EnhanceCommand extends Command {
  const EnhanceCommand({super.timestamp});

  @override
  String? validate(GameState state, GameContext context) {
    // 광고 보호 대기 중인지 확인
    if (state.pendingAdProtection) {
      return 'pending_ad_protection';
    }

    // 다음 레벨 검 데이터 가져오기
    final targetSword = context.swordTable.getSword(state.currentLevel + 1);
    if (targetSword == null) {
      return 'max_level_reached';
    }

    // 비용 계산 (숙련도 할인 적용)
    final baseCost = targetSword.enhanceCost;
    final masteryLevel = context.masteryTable.getLevel(state.playerData.mastery.level);
    final discount = masteryLevel.costDiscount;
    final cost = (baseCost * (1 - discount)).floor();

    // 골드 확인
    if (!EconomyLogic().canAfford(state, cost)) {
      return 'insufficient_gold';
    }

    return null; // 유효함
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final events = <GameEvent>[];

    // 1. 비용 계산 및 골드 차감
    final targetSword = context.swordTable.getSword(state.currentLevel + 1)!;
    final baseCost = targetSword.enhanceCost;
    final masteryLevel = context.masteryTable.getLevel(state.playerData.mastery.level);
    final discount = masteryLevel.costDiscount;
    final cost = (baseCost * (1 - discount)).floor();

    final economyResult = EconomyLogic().spendGold(state, cost);
    var currentState = economyResult.newState;
    events.addAll(economyResult.events);

    // 2. 강화 시도
    final enhanceLogic = EnhanceLogic();
    final effectiveRate = enhanceLogic.getEffectiveRate(currentState, targetSword);
    final success = enhanceLogic.roll(effectiveRate, context.random);

    if (success) {
      // 성공 처리
      final successResult = enhanceLogic.handleSuccess(
        currentState,
        targetSword,
        context.swordTable,
      );
      currentState = successResult.newState;
      events.addAll(successResult.events);

      // 통계 업데이트
      final stats = currentState.playerData.stats;
      final newLevel = currentState.currentLevel;

      final updatedStats = stats.copyWith(
        highestEnhanceLevel: max(stats.highestEnhanceLevel, newLevel),
        weeklyHighestLevel: max(stats.weeklyHighestLevel, newLevel),
        totalEnhanceAttempts: stats.totalEnhanceAttempts + 1,
        currentConsecutiveSuccess: stats.currentConsecutiveSuccess + 1,
        maxConsecutiveSuccess: max(
          stats.maxConsecutiveSuccess,
          stats.currentConsecutiveSuccess + 1,
        ),
        currentConsecutiveFail: 0,
      );

      currentState = currentState.copyWith(
        playerData: currentState.playerData.copyWith(stats: updatedStats),
      );
    } else {
      // 실패 처리
      final failResult = enhanceLogic.handleFail(
        currentState,
        context.swordTable,
        context,
      );
      currentState = failResult.newState;
      events.addAll(failResult.events);

      // 실제 파괴 여부는 이벤트의 destroyed 플래그로 판단
      final failEvent = failResult.events.whereType<EnhanceFailEvent>().first;
      final destroyed = failEvent.destroyed;

      // 파괴 확정 처리 (실제 파괴 + 광고 보호 대기가 아닌 경우)
      if (destroyed && !currentState.pendingAdProtection) {
        currentState = GameSessionLogic().resetToWoodenSword(
          currentState,
          context.swordTable,
        );
      }

      // 통계 업데이트
      final stats = currentState.playerData.stats;

      final updatedStats = stats.copyWith(
        totalDestroys: destroyed ? stats.totalDestroys + 1 : stats.totalDestroys,
        totalEnhanceAttempts: stats.totalEnhanceAttempts + 1,
        currentConsecutiveFail: stats.currentConsecutiveFail + 1,
        maxConsecutiveFail: max(
          stats.maxConsecutiveFail,
          stats.currentConsecutiveFail + 1,
        ),
        currentConsecutiveSuccess: 0,
      );

      currentState = currentState.copyWith(
        playerData: currentState.playerData.copyWith(stats: updatedStats),
      );
    }

    return CommandResult(newState: currentState, events: events);
  }
}
