/// P2-35: Firebase 익명 로그인 서비스
/// 실제 Firebase 연동은 firebase_auth 패키지 추가 후 구현
abstract class AuthService {
  Future<String?> signInAnonymously();
  String? get currentUserId;
  bool get isSignedIn;
}

/// 개발/테스트용 스텁 — Firebase 없이 동작
class StubAuthService implements AuthService {
  String? _userId;

  @override
  Future<String?> signInAnonymously() async {
    // 스텁: 고정 UID 반환
    _userId = 'stub_user_${DateTime.now().millisecondsSinceEpoch}';
    return _userId;
  }

  @override
  String? get currentUserId => _userId;

  @override
  bool get isSignedIn => _userId != null;
}
