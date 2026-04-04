import 'package:game_core/game_core.dart';

/// 테스트용 — 고정 시각, advance로 시간 이동
class FakeTimeProvider implements TimeProvider {
  DateTime _now;

  FakeTimeProvider([DateTime? initial])
      : _now = initial ?? DateTime(2025, 1, 1);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void set(DateTime dt) => _now = dt;
}
