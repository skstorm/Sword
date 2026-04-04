import 'enhance_animation_controller.dart';
import 'enhance_animation_config.dart';

/// P1용 최소 연출 — 서스펜스 딜레이, 텍스트 애니메이션만
class BasicEnhanceAnimation implements EnhanceAnimationController {
  @override
  Future<void> playEnhanceAttempt(int level, EnhanceAnimationConfig config) async {
    await Future.delayed(config.suspenseDuration);
  }

  @override
  Future<void> playSuccess(int prevLevel, int newLevel, EnhanceAnimationConfig config) async {
    // P1: simple delay, actual visual handled by view widget
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> playDestroy(int destroyedLevel, EnhanceAnimationConfig config) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> playSell(int level, int goldGained) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> playCollect(int level, String swordName) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  bool canSkip(int level) => level <= 3; // Lv.3+ mastery allows skip for low levels
}
