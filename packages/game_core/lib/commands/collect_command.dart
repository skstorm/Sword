import 'command.dart';
import '../events/game_event.dart';
import '../logic/collection_logic.dart';
import '../logic/game_session_logic.dart';
import '../models/game_state.dart';

/// 수집 커맨드 — 현재 검을 컬렉션에 등록
class CollectCommand extends Command {
  const CollectCommand({super.timestamp});

  @override
  String? validate(GameState state, GameContext context) {
    if (state.pendingAdProtection) return 'pending_ad_protection';
    if (state.currentLevel < 10) return 'level_too_low';
    if (!state.currentSword.collectible) return 'not_collectible';
    return null;
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final events = <GameEvent>[];

    // 1. 컬렉션 등록
    final collectResult = CollectionLogic().collect(state);
    var currentState = collectResult.newState;
    events.addAll(collectResult.events);

    // 2. 나무검으로 리셋
    currentState = GameSessionLogic().resetToWoodenSword(
      currentState,
      context.swordTable,
    );

    return CommandResult(newState: currentState, events: events);
  }
}
