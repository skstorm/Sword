import 'game_event.dart';

/// 장인 숙련도 레벨업 이벤트
class MasteryLevelUpEvent extends GameEvent {
  final int newLevel;
  final String? reward;
  const MasteryLevelUpEvent({required this.newLevel, this.reward});
}
