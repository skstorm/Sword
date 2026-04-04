/// 게임 이벤트 기본 인터페이스 — 상태 변경 알림 (출력)
abstract class GameEvent {
  const GameEvent();
}

/// 유효하지 않은 커맨드 시도 시 발행되는 이벤트
class CommandRejectedEvent extends GameEvent {
  final String commandType;
  final String reason;

  const CommandRejectedEvent({
    required this.commandType,
    required this.reason,
  });

  @override
  String toString() =>
      'CommandRejectedEvent($commandType rejected: $reason)';
}
