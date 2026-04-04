import 'enhance_animation_config.dart';

/// 강화 연출 컨트롤러 — 구현체를 교체하면 연출 전체가 바뀜
abstract class EnhanceAnimationController {
  Future<void> playEnhanceAttempt(int level, EnhanceAnimationConfig config);
  Future<void> playSuccess(int prevLevel, int newLevel, EnhanceAnimationConfig config);
  Future<void> playDestroy(int destroyedLevel, EnhanceAnimationConfig config);
  Future<void> playSell(int level, int goldGained);
  Future<void> playCollect(int level, String swordName);
  bool canSkip(int level);
}
