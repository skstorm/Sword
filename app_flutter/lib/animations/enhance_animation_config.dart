import 'dart:ui';

class EnhanceAnimationConfig {
  final int levelFrom;
  final int levelTo;
  final Duration suspenseDuration;
  final double screenShakeIntensity;
  final Color effectColor;
  final double effectScale;
  final bool enableHaptic;
  final String? successSoundId;
  final String? destroySoundId;

  const EnhanceAnimationConfig({
    required this.levelFrom,
    required this.levelTo,
    required this.suspenseDuration,
    this.screenShakeIntensity = 0,
    required this.effectColor,
    this.effectScale = 1.0,
    this.enableHaptic = false,
    this.successSoundId,
    this.destroySoundId,
  });
}

/// Config table with presets per stage range
class EnhanceAnimationConfigTable {
  final List<EnhanceAnimationConfig> _configs;
  EnhanceAnimationConfigTable(this._configs);

  EnhanceAnimationConfig forLevel(int level) {
    return _configs.firstWhere(
      (c) => level >= c.levelFrom && level <= c.levelTo,
      orElse: () => _configs.last,
    );
  }

  /// Default presets from the design doc:
  /// +1~+5: 0.5s suspense, no shake, grey, 1.0x, no haptic
  /// +6~+9: 1.0s, light shake, blue, 1.5x, haptic
  /// +10~+14: 1.5s, medium shake, purple, 2.0x, haptic
  /// +15~+17: 2.5s, strong shake, gold, 3.0x, haptic
  /// +18~+20: 3.0s, max shake, rainbow(white), 4.0x, haptic
  factory EnhanceAnimationConfigTable.fromDefaults() {
    return EnhanceAnimationConfigTable([
      EnhanceAnimationConfig(
        levelFrom: 1, levelTo: 5,
        suspenseDuration: Duration(milliseconds: 500),
        screenShakeIntensity: 0,
        effectColor: Color(0xFF9E9E9E), // grey
        effectScale: 1.0,
      ),
      EnhanceAnimationConfig(
        levelFrom: 6, levelTo: 9,
        suspenseDuration: Duration(milliseconds: 1000),
        screenShakeIntensity: 0.3,
        effectColor: Color(0xFF2196F3), // blue
        effectScale: 1.5,
        enableHaptic: true,
      ),
      EnhanceAnimationConfig(
        levelFrom: 10, levelTo: 14,
        suspenseDuration: Duration(milliseconds: 1500),
        screenShakeIntensity: 0.6,
        effectColor: Color(0xFF9C27B0), // purple
        effectScale: 2.0,
        enableHaptic: true,
      ),
      EnhanceAnimationConfig(
        levelFrom: 15, levelTo: 17,
        suspenseDuration: Duration(milliseconds: 2500),
        screenShakeIntensity: 0.8,
        effectColor: Color(0xFFFFD700), // gold
        effectScale: 3.0,
        enableHaptic: true,
      ),
      EnhanceAnimationConfig(
        levelFrom: 18, levelTo: 20,
        suspenseDuration: Duration(milliseconds: 3000),
        screenShakeIntensity: 1.0,
        effectColor: Color(0xFFFFFFFF), // white/rainbow
        effectScale: 4.0,
        enableHaptic: true,
      ),
    ]);
  }
}
