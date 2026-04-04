import 'dart:math';

import 'package:game_core/game_core.dart';

/// 테스트용 — 고정값 또는 시드 기반 난수
class FakeRandomProvider implements RandomProvider {
  double _value;
  final Random? _seededRandom;

  /// 고정값 모드 — nextDouble()가 항상 같은 값 반환
  FakeRandomProvider([this._value = 0.5]) : _seededRandom = null;

  /// 시드 모드 — 결정론적 난수 시퀀스
  FakeRandomProvider.seeded(int seed)
      : _value = 0,
        _seededRandom = Random(seed);

  @override
  double nextDouble() {
    if (_seededRandom != null) return _seededRandom!.nextDouble();
    return _value;
  }

  void setNext(double v) => _value = v;
}
