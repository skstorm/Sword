import 'dart:async';

import '../commands/command.dart';
import '../events/game_event.dart';
import '../models/game_state.dart';
import 'session_recorder.dart';

/// 게임 엔진 — 커맨드 수신 → validate → 실행 → 이벤트 발행
class GameEngine {
  GameState _state;
  final GameContext _context;
  final SessionRecorder? _recorder;

  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get events => _eventController.stream;
  GameState get state => _state;

  GameEngine({
    required GameState initialState,
    required GameContext context,
    SessionRecorder? recorder,
  })  : _state = initialState,
        _context = context,
        _recorder = recorder;

  void dispatch(Command command) {
    // 1. 유효성 검증
    final rejection = command.validate(_state, _context);
    if (rejection != null) {
      _eventController.add(CommandRejectedEvent(
        commandType: command.runtimeType.toString(),
        reason: rejection,
      ));
      return;
    }

    // 2. 커맨드 기록 (validate 통과한 것만)
    _recorder?.record(command);

    // 3. 로직 실행
    final result = command.execute(_state, _context);

    // 4. 상태 갱신
    _state = result.newState;

    // 5. 이벤트 발행
    for (final event in result.events) {
      _eventController.add(event);
    }
  }

  void dispose() {
    _eventController.close();
  }
}
