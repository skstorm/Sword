import '../events/game_event.dart';
import '../models/game_state.dart';
import '../engine/game_context.dart';

// Re-export for backward compatibility
export '../logic/logic_result.dart';
export '../engine/game_context.dart';

/// 커맨드 실행 결과 — 새로운 상태 + 발생한 이벤트 목록
class CommandResult {
  final GameState newState;
  final List<GameEvent> events;

  const CommandResult({required this.newState, required this.events});
}

/// 유저 액션 커맨드 기본 인터페이스
abstract class Command {
  final int timestamp;

  const Command({this.timestamp = 0});

  /// 유효성 검증 — null이면 유효, 문자열이면 거부 사유
  String? validate(GameState state, GameContext context);

  /// 실행 — validate() 통과 후에만 호출됨
  CommandResult execute(GameState state, GameContext context);
}
