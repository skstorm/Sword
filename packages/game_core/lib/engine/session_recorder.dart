import '../commands/command.dart';
import '../models/game_state.dart';

/// 세션 기록 데이터 (P3에서 상세 구현)
class SessionRecord {
  final int randomSeed;
  final DateTime startTime;
  final GameState initialState;
  final List<Command> commands;

  const SessionRecord({
    required this.randomSeed,
    required this.startTime,
    required this.initialState,
    required this.commands,
  });
}

/// 커맨드/시드 기록 (P3에서 구현, P0~P1에서는 null로 주입)
class SessionRecorder {
  final List<Command> _commands = [];

  void record(Command command) {
    _commands.add(command);
  }

  List<Command> get commands => List.unmodifiable(_commands);
}
