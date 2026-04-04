/// P2-32: 광고 서비스 인터페이스 + 스텁
/// 실제 AdMob 연동은 google_mobile_ads 패키지 추가 후 구현
abstract class AdService {
  Future<bool> showRewardedAd();
}

/// 개발/테스트용 스텁 — 항상 광고 시청 성공
class StubAdService implements AdService {
  @override
  Future<bool> showRewardedAd() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
