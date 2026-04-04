import '../events/game_event.dart';
import '../models/game_state.dart';

/// Logic 모듈의 반환 타입
class LogicResult {
  final GameState newState;
  final List<GameEvent> events;

  LogicResult(this.newState, [this.events = const []]);
}
