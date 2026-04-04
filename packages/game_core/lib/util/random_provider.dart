/// 난수 추상화 — 시드 기반 결정론적 실행 보장
abstract class RandomProvider {
  /// 0.0 이상 1.0 미만의 난수 반환
  double nextDouble();
}
