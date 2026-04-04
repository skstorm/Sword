import 'command.dart';
import '../events/game_event.dart';
import '../events/fragment_event.dart';
import '../logic/fragment_logic.dart';
import '../logic/game_session_logic.dart';
import '../models/game_state.dart';

/// 광고 보호권 거부 시 파괴 확정 커맨드
class ConfirmDestroyCommand extends Command {
  const ConfirmDestroyCommand({super.timestamp});

  @override
  String? validate(GameState state, GameContext context) {
    if (!state.pendingAdProtection) return 'no_pending_destruction';
    return null;
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final events = <GameEvent>[];
    var s = state;

    // 1. 파편 지급 (숙련도 보너스 포함)
    final masteryLevel = context.masteryTable.getLevel(s.playerData.mastery.level);
    final fragmentBonus = masteryLevel.fragmentBonus;
    final fragResult = FragmentLogic().giveFragments(s, fragmentBonus);
    s = fragResult.newState;
    events.addAll(fragResult.events);

    // 2. 나무검으로 리셋
    s = GameSessionLogic().resetToWoodenSword(s, context.swordTable);

    return CommandResult(newState: s, events: events);
  }
}
