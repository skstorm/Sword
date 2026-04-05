import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// 게임 상태를 자동으로 관리하는 Notifier.
/// GameEngine을 래핑하고, events stream을 구독하여
/// 상태 변경 시 자동으로 UI를 갱신한다.
class GameNotifier extends AutoDisposeNotifier<GameState?> {
  GameEngine? _engine;
  StreamSubscription<GameEvent>? _eventSub;

  /// 최근 이벤트 (UI에서 메시지 표시용)
  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  @override
  GameState? build() => null;

  /// 엔진 초기화 — FutureProvider에서 엔진이 준비되면 호출
  void initialize(GameEngine engine) {
    _engine = engine;
    state = engine.state;
    _eventSub?.cancel();
    _eventSub = engine.events.listen((event) {
      state = engine.state;
      _eventController.add(event);
    });
    ref.onDispose(() {
      _eventSub?.cancel();
      _eventController.close();
    });
  }

  /// 커맨드 디스패치 — 엔진에 전달, 상태는 자동 동기화됨
  void dispatch(Command command) {
    _engine?.dispatch(command);
  }

  /// 현재 엔진 참조 (애니메이션 등에서 state 직접 참조 필요 시)
  GameEngine? get engine => _engine;
}
