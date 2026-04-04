import 'command.dart';
import '../events/game_event.dart';
import '../events/economy_event.dart';
import '../logic/economy_logic.dart';
import '../logic/game_session_logic.dart';
import '../models/game_state.dart';

/// 판매 커맨드
class SellCommand extends Command {
  const SellCommand({super.timestamp});

  @override
  String? validate(GameState state, GameContext context) {
    // 나무 검은 판매 불가
    if (state.currentLevel == 0) {
      return 'cannot_sell_wooden_sword';
    }

    // 광고 보호 대기 중인지 확인
    if (state.pendingAdProtection) {
      return 'pending_ad_protection';
    }

    return null; // 유효함
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final events = <GameEvent>[];

    // 1. 판매 가격 가져오기
    final sellPrice = state.currentSword.sellPrice ?? 0;

    // 2. 골드 획득
    final economyResult = EconomyLogic().addGold(state, sellPrice, 'sell');
    var currentState = economyResult.newState;
    events.addAll(economyResult.events);

    // 3. 판매 이벤트 추가
    final sellEvent = SellEvent(
      soldLevel: state.currentLevel,
      soldSwordName: state.currentSword.name,
      goldGained: sellPrice,
    );
    events.add(sellEvent);

    // 4. 나무 검으로 리셋
    currentState = GameSessionLogic().resetToWoodenSword(
      currentState,
      context.swordTable,
    );

    // 5. 통계 업데이트
    final stats = currentState.playerData.stats;
    final updatedStats = stats.copyWith(
      totalSells: stats.totalSells + 1,
      totalGoldEarned: stats.totalGoldEarned + sellPrice,
    );

    currentState = currentState.copyWith(
      playerData: currentState.playerData.copyWith(stats: updatedStats),
    );

    return CommandResult(newState: currentState, events: events);
  }
}
