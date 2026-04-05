import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// 아이템 사용 + 부스터 칩 영역
class ItemChipsWidget extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<ItemType> onUseItem;
  final ValueChanged<AdType> onWatchAd;

  const ItemChipsWidget({
    super.key,
    required this.gameState,
    required this.onUseItem,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    final inv = gameState.playerData.inventory;
    final hasProtection = gameState.hasActiveProtection;
    final hasBlessing = gameState.activeModifiers.any((m) => m is BlessingScrollModifier);
    final hasBooster = gameState.activeModifiers.any((m) => m is AdBoosterModifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (hasProtection)
          const Chip(
            label: Text('보호중'),
            avatar: Icon(Icons.shield, size: 18),
            backgroundColor: Colors.blue,
          )
        else
          ActionChip(
            avatar: const Icon(Icons.shield, size: 18),
            label: Text('부적 (${inv.protectionAmulets})'),
            onPressed: inv.protectionAmulets > 0
                ? () => onUseItem(ItemType.protectionAmulet)
                : null,
          ),
        if (hasBlessing)
          const Chip(
            label: Text('축복중'),
            avatar: Icon(Icons.auto_fix_high, size: 18),
            backgroundColor: Colors.purple,
          )
        else
          ActionChip(
            avatar: const Icon(Icons.auto_fix_high, size: 18),
            label: Text('주문서 (${inv.blessingScrolls})'),
            onPressed: inv.blessingScrolls > 0
                ? () => onUseItem(ItemType.blessingScroll)
                : null,
          ),
        if (hasBooster)
          const Chip(
            label: Text('부스터중'),
            avatar: Icon(Icons.play_circle, size: 18),
            backgroundColor: Colors.orange,
          )
        else
          ActionChip(
            avatar: const Icon(Icons.play_circle, size: 18),
            label: const Text('부스터 +5%'),
            onPressed: () => onWatchAd(AdType.booster),
          ),
      ],
    );
  }
}
