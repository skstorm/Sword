/// 확률 수정자 인터페이스
abstract class Modifier {
  double apply(double baseRate);
}

/// 축복의 주문서 — 확률 +5%p
class BlessingScrollModifier extends Modifier {
  @override
  double apply(double baseRate) => baseRate + 0.05;
}

/// 광고 부스터 — 확률 +5%p
class AdBoosterModifier extends Modifier {
  @override
  double apply(double baseRate) => baseRate + 0.05;
}
