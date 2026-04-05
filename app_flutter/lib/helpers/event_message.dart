import 'package:game_core/game_core.dart';

/// GameEvent → 사용자에게 보여줄 메시지 변환
String eventToMessage(GameEvent event) {
  if (event is EnhanceSuccessEvent) {
    return '강화 성공! +${event.newLevel} ${event.newSwordName}';
  } else if (event is EnhanceFailEvent) {
    if (event.destroyed) {
      return '강화 실패! 검이 파괴되었습니다...';
    }
    return '강화 실패! (보호됨)';
  } else if (event is SellEvent) {
    return '판매 완료! +${event.goldGained}골드';
  } else if (event is CollectEvent) {
    return '${event.collectedSwordName} 수집 완료!';
  } else if (event is FragmentGainEvent) {
    return '파편 ${event.amount}개 획득!';
  } else if (event is MasteryLevelUpEvent) {
    return '장인 숙련도 Lv.${event.newLevel} 달성!';
  } else if (event is AdRewardEvent) {
    switch (event.adType) {
      case AdType.protection:
        return '검이 복구되었습니다!';
      case AdType.gold:
        return '200골드 획득!';
      case AdType.booster:
        return '확률 부스터 적용!';
    }
  } else if (event is UseItemEvent) {
    final name = event.itemType == ItemType.protectionAmulet ? '보호의 부적' : '축복의 주문서';
    return '$name 사용!';
  } else if (event is CommandRejectedEvent) {
    return rejectionMessage(event.reason);
  }
  return '';
}

/// 거부 사유 → 메시지
String rejectionMessage(String reason) {
  switch (reason) {
    case 'insufficient_gold':
      return '골드가 부족합니다';
    case 'cannot_sell_wooden_sword':
      return '나무 검은 판매할 수 없습니다';
    case 'max_level_reached':
      return '최대 레벨에 도달했습니다';
    case 'pending_ad_protection':
      return '파괴 복구를 먼저 결정하세요';
    case 'no_item':
      return '아이템이 없습니다';
    default:
      return '불가능한 행동입니다';
  }
}
