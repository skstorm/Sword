import 'game_event.dart';

/// 광고 보상 타입
enum AdType {
  protection,
  gold,
  booster,
}

/// 광고 보상 이벤트
class AdRewardEvent extends GameEvent {
  final AdType adType;
  final String rewardDetail;
  const AdRewardEvent({required this.adType, required this.rewardDetail});
}
