import 'package:game_core/game_core.dart';
import '../services/auth_service.dart';
import 'hive_storage_repository.dart';

/// P2-36: Firestore 원격 저장소 구현
/// 실제 Firestore 연동은 cloud_firestore 패키지 추가 후 구현
/// 현재는 스텁 — InMemory로 동작하되 인터페이스는 Firebase 준비 완료
class FirebaseRepository implements StorageRepository {
  final AuthService _auth;

  // 스텁: 메모리에 JSON으로 저장 (실제로는 Firestore document)
  Map<String, dynamic>? _remoteData;

  FirebaseRepository({required AuthService auth}) : _auth = auth;

  @override
  Future<PlayerData> load() async {
    if (!_auth.isSignedIn) {
      await _auth.signInAnonymously();
    }

    // 스텁: 메모리에서 로드
    // 실제 구현: Firestore.collection('players').doc(userId).get()
    if (_remoteData == null) return PlayerData();
    return HiveStorageRepository.fromJsonPublic(_remoteData!);
  }

  @override
  Future<void> save(PlayerData data) async {
    if (!_auth.isSignedIn) {
      await _auth.signInAnonymously();
    }

    // 스텁: 메모리에 저장
    // 실제 구현: Firestore.collection('players').doc(userId).set(json)
    _remoteData = HiveStorageRepository.toJsonPublic(data);
  }
}
