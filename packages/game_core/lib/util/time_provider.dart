/// 시간 추상화 — 일일 제한, 주간 리셋 등 시간 의존 로직의 테스트/리플레이 지원
abstract class TimeProvider {
  DateTime now();
}
