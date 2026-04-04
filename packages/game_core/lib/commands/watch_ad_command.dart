import 'command.dart';
import '../events/ad_event.dart';
import '../logic/ad_reward_logic.dart';
import '../models/game_state.dart';

/// 광고 시청 커맨드
class WatchAdCommand extends Command {
  final AdType adType;

  const WatchAdCommand({required this.adType, super.timestamp});

  @override
  String? validate(GameState state, GameContext context) {
    switch (adType) {
      case AdType.protection:
        if (!state.pendingAdProtection) return 'no_pending_protection';
        if (!const AdRewardLogic().canUseProtection(state, context.time)) {
          return 'daily_limit_reached';
        }
      case AdType.gold:
        break; // 무제한
      case AdType.booster:
        if (state.pendingAdProtection) return 'pending_ad_protection';
    }
    return null;
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    const adLogic = AdRewardLogic();
    final LogicResult result;

    switch (adType) {
      case AdType.protection:
        result = adLogic.applyProtection(state, context.time);
      case AdType.gold:
        result = adLogic.giveGold(state);
      case AdType.booster:
        result = adLogic.applyBooster(state);
    }

    return CommandResult(newState: result.newState, events: result.events);
  }
}
