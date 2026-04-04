import 'game_event.dart';

class EnhanceSuccessEvent extends GameEvent {
  final int prevLevel;
  final int newLevel;
  final String newSwordName;
  final int goldSpent;
  const EnhanceSuccessEvent({
    required this.prevLevel,
    required this.newLevel,
    required this.newSwordName,
    required this.goldSpent,
  });
}

class EnhanceFailEvent extends GameEvent {
  final int destroyedLevel;
  final String destroyedSwordName;
  final int fragmentsGained;
  final int goldSpent;
  final bool adProtectionAvailable;
  final bool destroyed; // false if protection amulet blocked it
  const EnhanceFailEvent({
    required this.destroyedLevel,
    required this.destroyedSwordName,
    required this.fragmentsGained,
    required this.goldSpent,
    required this.adProtectionAvailable,
    required this.destroyed,
  });
}
